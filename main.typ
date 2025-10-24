#show link: underline

= The Great Events Site Migration

In this paper-masquerading-as-a-research-paper-but-not-really-a-research-paper,
I will discuss the process of migrating the Events site of Purdue Hackers from
the antiquated NextJS-based codebase to a new AstroJS-based codebase. In the process,
I'll also go over the process of integrating all the event metadata and details
from Sanity, which we used to keep track of historical events, into the site codebase
itself using the Content Collections feature of AstroJS.

== Definitions

*NextJS* and *AstroJS* are two JavaScript (JS) frameworks that developers can use
to build their webapps and websites. NextJS is primarily developed by the Vercel
corporation, while AstroJS is built more by the community overall.

*Sanity* is a Content Management System (CMS), which ensures that "content" --
in our case, past event information and retrospectives -- all follow a specific
format so that our frontend can easily convert the data coming over from Sanity
into the final webpage that users can view. In addition, Sanity stores all the
information in a database, along with the image assets associated with each event.

Finally, *TailwindCSS* is a CSS framework that allows web developers and designers
to easily style the frontend (the part that users view) without having to maintain
a separate CSS file. This is achieved by having almost all CSS functionality
expressed as class names, which is included in the HTML markup.

== Motivation

Purdue Hackers hosts several events throughout the academic year, including Hack
Night, where creatives come together to work on projects and socialize. At midnight,
a Checkpoint ceremony is held, where people present their projects and what they've
been working on over the past two weeks, and lots of photos are taken for
posterity. Once the event is over, one of the organizers upload a postmortem
of the event, including all the media taken during the event.

The initial version of our events site was developed by Matthew Stanciu, the
past president of Purdue Hackers. Events were managed on Airtable, before the
migration over to Sanity in January 2023 as Matthew wanted to use a real CMS
to manage our events. For the RSVP functionality and emailing potential attendees,
a GitHub Actions task ran that checked the RSVP email list hosted on Sanity and
then sent out an email via a third-party service. We used Mailgun, before
eventually switching over to Resend.

This system worked well for quite some time, but it wasn't without faults. The
initial signs of trouble were reported by our very own organizers, who would use
Sanity to write the postmortem to events. They would often report that Sanity
was unreliable; it would lose uploaded image assets and force them to start over
from scratch.

Additionally, because Sanity hosted our event data, each user interaction would
require the server to query Sanity for the associated event information. A round
trip between the browser and server backend would occur, the server would make
another round trip to Sanity's servers, and then the response would then get sent
over to the user. This increased the overall latency and responsiveness of the
site, and required the backend to unnecessarily repeat the process of converting
the data from Sanity into a list of events and the event detail page for the users.
And as Sanity gave back the data in one giant payload, we had to use pagination
to not cause undue strain on the overall infrastructure. Even the index page, with
minimal information of just the title and date/time of the event, fetched the
entire event metadata from Sanity, wasting a lot of users' data.

After a lenghty discussion on the engineering channel for Purdue Hackers, a solution
was proposed: to statically generate the webpage, including all details about events
in the codebase once, then serving the minified HTML to users. AstroJS had the
promising feature of Content Collections that would allow us to achieve this goal,
so it was our first pick out of the list of alternatives to consider for this
migration, which had been on our roadmap for quite some time.

The final nail in the coffin came when Ray Arayilakath, the current president of
Purdue Hackers, transitioned the RSVP functionality over to Luma, a 3rd-party event
and ticketing platform. Thus, current and future events were solely managed on
this new platform, and the RSVP functionality and associated code became redundant
on our events site codebase. We decided to take this opportunity to rewrite the
codebase from scratch and base it off of AstroJS.

== First Steps

#let wipe_commit_url = "https://github.com/purduehackers/events/commit/97217e07426cf092e889a7102354bb3fe4e5edc0";
#let astrojs_init_commit_url = "https://github.com/purduehackers/events/commit/e0bd3b224ade828bb687d22a1abb8f733cae6af5";

On a separate branch,
#link(wipe_commit_url)[the first commit that wiped out our NextJS codebase]
#footnote[#link(wipe_commit_url)[#wipe_commit_url]] and
#link(astrojs_init_commit_url)[set up a clean AstroJS template was created]
#footnote[#link(astrojs_init_commit_url)[#astrojs_init_commit_url]]. This marked
the start of the migration attempt.

#let astro_tailwind_guide_url = "https://docs.astro.build/en/guides/styling/#tailwind";
Before even looking into downloading and migrating the event metadata from Sanity,
the initial structure of the events site was migrated by copying the HTML source
from our NextJS codebase straight into the index page in our AstroJS codebase.
After configuring #link(astro_tailwind_guide_url)[the official TailwindCSS plugin]
#footnote[#link(astro_tailwind_guide_url)[#astro_tailwind_guide_url]],
most of the styling displayed immediately with minor issues.

#figure(
  image("images/tailwindcss-frontend-migration.png", width: 100%),
  caption: [Left: the original events site with NextJS. Right: the initial AstroJS migration.],
)

While mixing styling with markup might be a questionable decision for some, the
choice of using TailwindCSS for our styling meant that migrating just the frontend
to a new codebase became significantly easier, because the frontend's classes
dictated how the content should be laid out on the page. Without having to set up
a transpiler for separate CSS files, a plugin was all that was needed to have
the page styling mimic the previous codebase.

One minor hurdle was that the old NextJS codebase utilized TailwindCSS v3, while
the official plugin targeted TailwindCSS v4. During the migration, some of the
configuration values defined in the dedicated `tailwind.config.js` file had to
be moved over as CSS directives, like `@theme`. TailwindCSS's extensive library
documentation helped immensely during this process, and I was able to match
the original styling of the site.

== Converting the events

#let sanity_query_lang_url = "https://www.sanity.io/docs/content-lake/how-queries-work";

The next stage was to preserve all of our old events and retrospectives. To achieve
this, I had to download the event metadata from Sanity. Sanity however, does not
use REST for their API endpoints. Instead, they have
#link(sanity_query_lang_url)[a custom query language named GROQ]
#footnote[#link(sanity_query_lang_url)[#sanity_query_lang_url]]
that I had to learn, just to query all the events that were stored in their
backend.

For comparison, a typical SQL statement to query for data would look something
like this:

```sql
SELECT * FROM events
WHERE date > 2020-03-24 AND date < 2025-01-01;
```

However, GROQ would require you to write:

```
*[_type == "event" && date > "2020-03-24" && date < "2025-01-01"]
```

Even though plain SQL could probably do most if not all of what GROQ achieves,
it was what Sanity used, so it was what I had to learn in order to progress with
the migration. Fortunately, I did not have to filter my result, as the goal was
to grab everything I could off of Sanity.

#let temporary_python_migration_commit_url = "https://github.com/purduehackers/events/tree/6e061709cc668f8c67cb586af6ede7211fce7b75/src/content";

Once the correct GROQ query was constructed, all the metadata could be downloaded
with a single request. However, this did not include any of the images that were
uploaded with the retrospectives. To facilitate this,
#link(temporary_python_migration_commit_url)[several Python scripts were written]
#footnote[#link(temporary_python_migration_commit_url)[#temporary_python_migration_commit_url]]
that handled the downloading, conversion, and renaming of all the events and
images into the correct respective folders. This took several tries, mainly due
to events with the same slug and names. In particular, Hack Nights without version
identifiers or "beta" Hack Nights that were held, confused the script and
required modification.

#let content_collection_config_url = "https://github.com/purduehackers/events/blob/main/src/content.config.ts";

But once the events were organized into each event category and the version-named
subfolder,
#link(content_collection_config_url)[a single Content Collection configuration file]
#footnote[#link(content_collection_config_url)[#content_collection_config_url]]
was all that was needed for AstroJS to correctly parse the schema and create a
collection of events that could be used to query past events.

As mentioned earlier, AstroJS has a neat feature called "Content Collections"
where you can define a schema in a configuration file. During compile time,
Astro will look at this schema and determine all the files that fit within this
schema with the glob pattern you have specified. If any files match the glob pattern
but do not validate against the provided schema, a compile-time error is raised,
making sure that all required data is accounted for in each event. This ensures
consistency between all of our events metadata, while allowing us to track changes
using Git commits.

== Retrospective

#let migration_bugs_url = "https://github.com/purduehackers/events/issues/97";

Overall, the migration of the event site was a success, and once the PR was merged,
a build job on Vercel ran and transparently replaced the old instance of our
NextJS site with our new AstroJS instance, with zero downtime for users. Nearly
all the functionality carried over, with
#link(migration_bugs_url)[only a handful of minor bugs]
#footnote[#link(migration_bugs_url)[#migration_bugs_url]]
that escaped the testing phase of the PR before merging.

Through this experience, I learned that intermediary scripts, like the Python
scripts we used to convert the events from the Sanity schema to AstroJS content
collections, don't have to be perfect or pretty. Since they're designed to be run
once and then discarded, the core objective is that they work, and in this instance,
they've clearly served their purpose.

That extends to styling libraries like TailwindCSS. When I initially approached
this library, I was part of the skeptics that thought mixing styling with the
markup wouldn't work too well. However, once the frontend is written, we typically
do not touch the markup and just import the component with the necessary data
to display it to the user, which means the only time we will interact with the
source is if we need to tweak the design, or migrate it like I've done here.
And when you're doing either of those tasks, viewing both the styling and the
markup is required, reducing the concern of combining the two.

== Future Plans

While the migration itself was successful, maintaining the site will continue until
we no longer need it or migrate off to something new. We already have a couple of
ideas planned for the rewritten events site, most notably a redesign that will
allow us to test out ideas for our upcoming overall brand renewal. As the codebase
has been cleaned up, testing out new changes should be comparatively easy as we
no longer have to account for features that we no longer use, such as the RSVP
capabilities of the old events site.

After the migrated site launched, we received feedback that submitting new events
and retrospectives through GitHub pull-requests add significant friction. This
may come as ironic, given that I've just talked about the benefits that Astro's
static content collections bring, but in the future, we may look into dynamically
storing events metadata on a database, which would allow us to design a clean,
friendly administrative interface that organizers can use to submit event details.

Another issue that cropped up was that, as it currently stands, our events site
repository sits at nearly 2 GB of space used once cloned. This is due to all the
image assets that we include with each event retrospective. For comparison, my
personal website which was also built atop AstroJS didn't run into this issue with
only a handful of images per post, if any. On our events site, each of our events
retrospectives can contain around 20 to 50 images at once, which will not scale
due to asset size. This is another area we could improve in, by perhaps storing
images in a platform that's more suitable for the task, such as a CDN.

All in all, the rewrite has given us a solid foundation to improve our events site
and to try out new things before they are propagated to the rest of our infrastructure.


== Acknowledgements

Finally, many thanks to the various Purdue Hacker organizers and members for giving
me feedback and words of encouragement during the migration phase, as well as bug
reports that I didn't manage to catch pre- and post-deployment. I would also like
to thank Kartavya for organizing this SIGHORSE initiative and for giving me a chance
to write this paper.
