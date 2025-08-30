#show link: underline

= The Great Events Site Migration

In this paper-masquerading-as-a-research-paper-but-not-really-a-research-paper,
I will discuss the process of migrating the Events site of Purdue Hackers from
the antiquated NextJS-based codebase to a new AstroJS-based codebase, while
integrating all of the event metadata and details into the site codebase itself
using the Content Collections feature of AstroJS. I will also go over the process
that was necessary to download and convert the event metadata from Sanity, a
Content Management System (CMS) that we used to keep track of historical events.

== Motivation

Purdue Hackers hosts several events throughout the academic year, including Hack
Night, where creatives come together to work on projects and socialize. At midnight,
a Checkpoints ceremony is held, where people present their projects and what they've
been working on over the past two weeks, and lots of photos are taken for
posterity. Once the event is over, one of the organizers upload a postmortem
of the event, including all of the media taken during the event.

This portion of writing the postmortem was particularly problematic with Sanity.
Organizers tasked with this would complain that Sanity would frequently lose
the media uploaded, forcing them to start over from scratch.

Additionally, because there was an additional step where the events data had to
be fetched from Sanity, the overall latency was increased, not to mention the
additional processing required on the server to display the list of events and
the event detail to the users. This had to be repeated for each request, requiring
the use of pagination to keep the data payload small. Even the index page, where
minimal information of just the title and date/time of the event, fetched the
entire event metadata from Sanity, wasting a lot of users' data.

The solution was to statically generate the webpage by including all details
about events in the codebase once, then serving the minified HTML to users.
AstroJS had the promising feature of Content Collections that would allow us
to achieve this goal, so this migration had been on our roadmap for a while.

== First Steps

On a separate branch, [the first commit that wiped out our NextJS codebase][nextjs-remove-commit]
and [set up a clean AstroJS template was created][astrojs-template-commit]. This
marked the start of the migration attempt.

[nextjs-remove-commit]: https://github.com/purduehackers/events/commit/97217e07426cf092e889a7102354bb3fe4e5edc0
[astrojs-template-commit]: https://github.com/purduehackers/events/commit/e0bd3b224ade828bb687d22a1abb8f733cae6af5

Before even looking into downloading and migrating the event metadata from Sanity,
the initial structure of the events site was migrated by copying the HTML source
from our NextJS codebase straight into the index page in our AstroJS codebase.
After configuring [the official TailwindCSS plugin][astrojs-tailwindcss-plugin],
most of the styling displayed immediately with minor issues.

#figure(
  image("images/tailwindcss-frontend-migration.png", width: 100%),
  caption: [Left: the original events site with NextJS. Right: the initial AstroJS migration.],
)

[astrojs-tailwindcss-plugin]: https://docs.astro.build/en/guides/styling/#tailwind

While mixing styling with markup might be a questionable decision for some, the
choice of using TailwindCSS for our styling meant that migrating just the frontend
to a new codebase became significantly easier, because the frontend's classes
dictated how the content should be laid out on the page already.
