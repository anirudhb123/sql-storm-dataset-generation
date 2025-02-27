
WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        c.kind AS movie_type,
        STRING_AGG(a.name, ', ') AS actor_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM
        title t
    JOIN
        kind_type c ON t.kind_id = c.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kc ON mk.keyword_id = kc.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, c.kind
),
DetailedInfo AS (
    SELECT
        md.title_id,
        md.title,
        md.production_year,
        md.movie_type,
        md.actor_names,
        md.keyword_count,
        COALESCE(mi.info, 'No Info') AS additional_info
    FROM
        MovieDetails md
    LEFT JOIN
        movie_info mi ON md.title_id = mi.movie_id
    WHERE
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Runtime')
)
SELECT
    di.title AS "Movie Title",
    di.production_year AS "Release Year",
    di.movie_type AS "Type",
    di.actor_names AS "Actors",
    di.keyword_count AS "Keyword Count",
    di.additional_info AS "Runtime Info"
FROM
    DetailedInfo di
ORDER BY
    di.production_year DESC,
    di.keyword_count DESC;
