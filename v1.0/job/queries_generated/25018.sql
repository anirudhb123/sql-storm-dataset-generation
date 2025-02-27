WITH MovieDetails AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_type,
        k.keyword AS movie_keyword,
        p.info AS person_info
    FROM
        title t
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type c ON ci.role_id = c.id
    LEFT JOIN
        person_info p ON a.person_id = p.person_id
    WHERE
        t.production_year >= 2000
        AND k.keyword ILIKE '%action%'
),
AggregatedData AS (
    SELECT
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT md.actor_name) AS actor_count,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT md.role_type, ', ') AS roles,
        MAX(p.info) AS personal_info
    FROM
        MovieDetails md
    LEFT JOIN
        person_info p ON md.actor_name = p.info
    GROUP BY
        md.movie_title, md.production_year
)
SELECT
    movie_title,
    production_year,
    actor_count,
    keywords,
    roles,
    personal_info
FROM
    AggregatedData
ORDER BY
    production_year DESC, actor_count DESC;

This query retrieves and aggregates detailed information about movies released after the year 2000 that include the keyword "action". It includes the movie title, production year, count of unique actors, keywords associated with each movie, roles played by those actors, and any personal information available related to the actors. Results are ordered by production year and actor count for easier examination of trends in the dataset.
