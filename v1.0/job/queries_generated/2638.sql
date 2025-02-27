WITH movie_data AS (
    SELECT
        a.title,
        a.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        MAX(mi.info) FILTER (WHERE it.info = 'description') AS description
    FROM
        aka_title a
    LEFT JOIN
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN
        aka_name c ON c.person_id = ci.person_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = a.id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN
        movie_info mi ON mi.movie_id = a.id
    LEFT JOIN
        info_type it ON it.id = mi.info_type_id
    WHERE
        a.production_year >= 2000
        AND a.production_year < 2023
        AND (a.kind_id = 1 OR a.kind_id = 2)
    GROUP BY
        a.id
),
ranked_movies AS (
    SELECT
        title,
        production_year,
        cast_names,
        company_count,
        keyword_count,
        description,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_count DESC, company_count DESC) AS rn
    FROM
        movie_data
)
SELECT
    rm.title,
    rm.production_year,
    COALESCE(rm.cast_names, '{}') AS cast_names,
    rm.company_count,
    rm.keyword_count,
    COALESCE(rm.description, 'No description available') AS description
FROM
    ranked_movies rm
WHERE
    rm.rn <= 10
ORDER BY
    rm.production_year DESC,
    rm.keyword_count DESC;
