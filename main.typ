#show link: underline

= The Great Events Site Migration

In this paper-masquerading-as-a-research-paper-but-not-really-a-research-paper,
I will discuss the process of migrating the Events site of Purdue Hackers from
the antiquated NextJS-based codebase to a new AstroJS-based codebase. In the process,
I'll also go over the process of integrating all of the event metadata and details
from Sanity, which we used to keep track of historical events, into the site codebase
itself using the Content Collections feature of AstroJS.

== Definitions

NextJS and AstroJS are two Javascript (JS) frameworks that developers can use to
build their webapps and websites. NextJS is primarily developed by the Vercel
corporation, while AstroJS is built more by the community overall.

Sanity is a Content Management System (CMS), which ensures that "content" --
in our case, past event information and retrospectives -- all follow a specific
format so that our frontend can easily convert the data coming over from Sanity
into the final webpage that users can view. In addition, Sanity stores all of the
information in a database, along with the image assets associated with each event.

Finally, TailwindCSS is a CSS framework that allows web developers and designers
to easily style the frontend (the part that users view) without having to maintain
a separate CSS file. This is achieved by having almost all CSS functionality
expressed as class names, which is included in the HTML markup.

== Motivation

Purdue Hackers hosts several events throughout the academic year, including Hack
Night, where creatives come together to work on projects and socialize. At midnight,
a Checkpoints ceremony is held, where people present their projects and what they've
been working on over the past two weeks, and lots of photos are taken for
posterity. Once the event is over, one of the organizers upload a postmortem
of the event, including all of the media taken during the event.

The initial version of our events site was developed by Matthew Stanciu, our
past president of Purdue Hackers. Events were managed on Airtable, before the
migration over to Sanity in January of 2023 as Matthew wanted to use a real CMS
to manage our events. For the RSVP functionality and emailing potential attendees,
a GitHub Actions task ran that checked the RSVP email list hosted on Sanity and
then sent out an email via a third-party service. We used Mailgun, before
eventually switching over to Resend.

This system worked well for quite some time, but it wasn't without outstanding
faults. The initial signs of trouble were reported by our very own organizers,
who would use Sanity to write the postmortem to events. They would often report
that Sanity was unreliable, by losing uploaded image assets and forcing them to
start over from scratch.

Additionally, because Sanity hosted our events data, each user interaction would
require the server to query Sanity for the associated event information. A round
trip between the browser and server backend would occur, the server would make
another round trip to Sanity's servers, and then the response would then get sent
over to the user. This increased the overall latency and responsiveness of the
site, and required the backend to unnecessarily repeat the process of converting
the data from Sanity into a list of events and the event detail page for the users.
And as Sanity gave back the data in one giant payload, we had to use pagination
to not cause undue strain on the overall infrastructure. Even the index page, where
minimal information of just the title and date/time of the event, fetched the
entire event metadata from Sanity, wasting a lot of users' data.

The solution was to statically generate the webpage by including all details
about events in the codebase once, then serving the minified HTML to users.
AstroJS had the promising feature of Content Collections that would allow us
to achieve this goal, so this migration had been on our roadmap for a while.

== First Steps

On a separate branch,
#link("https://github.com/purduehackers/events/commit/97217e07426cf092e889a7102354bb3fe4e5edc0")[the first commit that wiped out our NextJS codebase] and 
#link("https://github.com/purduehackers/events/commit/e0bd3b224ade828bb687d22a1abb8f733cae6af5")[set up a clean AstroJS template was created].
This marked the start of the migration attempt.

Before even looking into downloading and migrating the event metadata from Sanity,
the initial structure of the events site was migrated by copying the HTML source
from our NextJS codebase straight into the index page in our AstroJS codebase.
After configuring #link("https://docs.astro.build/en/guides/styling/#tailwind")[the official TailwindCSS plugin],
most of the styling displayed immediately
with minor issues.

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

The next stage was to preserve all of our old events and retrospectives. To achieve
this, I had to download the event metadata from Sanity. Sanity however, does not
use REST for their API endpoints. Instead, they have
#link("https://www.sanity.io/docs/content-lake/how-queries-work")[a custom query language named GROQ]
that I had to learn, just to query all of the events that were stored in their
backend.

But once the correct query was constructed, all of the metadata could be downloaded
with a single request. However, this did not include any of the images that were
uploaded with the retrospectives. To facilitate this,
#link("https://github.com/purduehackers/events/tree/6e061709cc668f8c67cb586af6ede7211fce7b75/src/content")[several Python scripts were written]
that handled the downloading, conversion, and renaming of all of the events and
images into the correct respective folders.

This took several tries, mainly due to events with the same slug and names. In
particular, Hack Nights without version identifiers or "beta" Hack Nights that
were held confused the script and required modification.

But once the events were organized into each event category and the version-named
subfolder,
#link("https://github.com/purduehackers/events/blob/main/src/content.config.ts")[a single Content Collection configuration file]
was all that was needed for AstroJS to correctly parse the schema and create a
collection of events that could be used to query past events.

== Retrospective

Overall, the migration of the event site was a success, and once the PR was merged,
a build job on Vercel ran and transparently replaced the old instance of our
NextJS site with our new AstroJS instance, with zero downtime for users. Nearly
all of the functionality carried over, with
#link("https://github.com/purduehackers/events/issues/97")[only a handful of minor bugs]
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

Finally, many thanks to the various Purdue Hacker organizers and members for giving
me feedback and words of encouragement during the migration phase, as well as bug
reports that I didn't manage to catch pre- and post-deployment. I would also like
to thank Kartavya for organizing this SIGHORSE initiative and for giving me a chance
to write this paper.