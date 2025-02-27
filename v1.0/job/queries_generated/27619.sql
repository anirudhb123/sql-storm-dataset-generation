WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT a.name) AS actors
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type c ON mc.company_type_id = c.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year BETWEEN 2000 AND 2022
    GROUP BY
        t.id, t.title, t.production_year, k.keyword, c.kind
),
ActorStats AS (
    SELECT
        a.name AS actor_name,
        COUNT(DISTINCT md.movie_id) AS movie_count,
        STRING_AGG(DISTINCT md.title, ', ') AS titles
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        MovieDetails md ON ci.movie_id = md.movie_id
    GROUP BY
        a.name
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.company_type,
    AS.actor_name,
    AS.movie_count,
    AS.titles
FROM
    MovieDetails md
JOIN
    ActorStats a ON md.actors LIKE '%' || a.actor_name || '%'
ORDER BY
    md.production_year DESC, a.movie_count DESC;
