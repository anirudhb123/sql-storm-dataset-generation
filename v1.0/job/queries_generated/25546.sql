WITH ActorMovieTitles AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS production_year,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(mc.movie_id) AS company_count
    FROM
        aka_name a
    INNER JOIN
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN
        title t ON ci.movie_id = t.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        a.id, a.name, t.title, t.production_year, ct.kind
),
RankedActors AS (
    SELECT
        actor_id,
        actor_name,
        movie_title,
        production_year,
        company_type,
        keywords,
        company_count,
        RANK() OVER (PARTITION BY production_year ORDER BY company_count DESC) AS ranking
    FROM
        ActorMovieTitles
)
SELECT
    actor_name,
    movie_title,
    production_year,
    company_count,
    company_type,
    keywords
FROM
    RankedActors
WHERE
    ranking <= 5
ORDER BY
    production_year DESC, ranking;
