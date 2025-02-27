
WITH MovieDetails AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        k.keyword AS movie_keyword
    FROM
        title t
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        aka_title at ON at.id = t.id
    JOIN
        cast_info ci ON ci.movie_id = t.id
    JOIN
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id, k.keyword
)

SELECT
    MD.movie_title,
    MD.production_year,
    MD.kind_id,
    MD.actor_names,
    MD.company_types,
    MD.movie_keyword
FROM
    MovieDetails MD
WHERE
    MD.production_year > 2000
ORDER BY
    MD.production_year DESC, MD.movie_title ASC
LIMIT 100;
