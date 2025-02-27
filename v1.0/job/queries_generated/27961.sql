WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_kinds,
        STRING_AGG(DISTINCT p.gender, ', ') AS cast_genders,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM
        aka_title t
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type c ON mc.company_type_id = c.id
    JOIN
        cast_info ca ON t.id = ca.movie_id
    JOIN
        name p ON ca.person_id = p.id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'tagline')         
    GROUP BY
        t.id, t.title, t.production_year
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.company_kinds,
    md.cast_genders,
    md.actor_count,
    ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS ranking
FROM
    movie_details md
WHERE
    md.actor_count > 5
ORDER BY
    md.production_year DESC, md.actor_count DESC;

This query benchmarks string processing by extracting detailed information about movies, including the movie title, production year, associated keywords, company types, cast genders, and the number of actors involved. It uses Common Table Expressions (CTE) to organize the data collection and applies aggregation and filtering criteria to produce a refined result set. Additionally, it ranks the results based on the production year and actor count.
