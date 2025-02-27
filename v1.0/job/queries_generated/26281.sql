WITH MovieKeywordRankings AS (
    SELECT
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY COUNT(*) DESC) AS keyword_rank
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id, k.keyword
),
ActorMovieCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
RecentTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year >= 2020
    GROUP BY
        t.id, t.title, t.production_year, a.name
)
SELECT
    rt.title,
    rt.production_year,
    mk.keyword,
    mk.keyword_rank,
    ac.actor_count
FROM
    RecentTitles rt
JOIN
    MovieKeywordRankings mk ON rt.title_id = mk.movie_id
JOIN
    ActorMovieCounts ac ON rt.title_id = ac.movie_id
WHERE
    mk.keyword_rank <= 3 -- Top 3 keywords
ORDER BY
    rt.production_year DESC,
    ac.actor_count DESC;
