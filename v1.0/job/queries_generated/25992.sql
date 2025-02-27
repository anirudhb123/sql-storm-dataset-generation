WITH movie_data AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.md5sum AS actor_md5,
        pk.keyword AS movie_keyword,
        ct.kind AS company_type,
        ci.note AS cast_note
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword pk ON mk.keyword_id = pk.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        t.production_year >= 2000
        AND pk.keyword LIKE 'Action%'
),
aggregated_data AS (
    SELECT
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS cast_names,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        COUNT(DISTINCT actor_name) AS actor_count,
        COUNT(DISTINCT company_type) AS company_types
    FROM
        movie_data
    GROUP BY
        movie_title,
        production_year
)
SELECT 
    movie_title,
    production_year,
    cast_names,
    keywords,
    actor_count,
    company_types
FROM 
    aggregated_data
ORDER BY 
    production_year DESC, actor_count DESC;
