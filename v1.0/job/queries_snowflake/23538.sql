
WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_cast_count,
        LISTAGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
company_details AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS unique_company_count,
        LISTAGG(cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
keyword_details AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.unique_cast_count,
    cd.cast_names,
    co.unique_company_count,
    co.company_names,
    kd.keyword_count,
    kd.keywords,
    CASE 
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN '2000s'
        WHEN rm.production_year BETWEEN 2011 AND 2020 THEN '2010s'
        WHEN rm.production_year IS NULL THEN 'Year Unknown'
        ELSE 'Older'
    END AS decade_group
FROM
    ranked_movies rm
LEFT JOIN
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    company_details co ON rm.movie_id = co.movie_id
LEFT JOIN
    keyword_details kd ON rm.movie_id = kd.movie_id
WHERE
    (cd.unique_cast_count > 0 OR co.unique_company_count > 0 OR kd.keyword_count > 0)
    AND rm.title_rank <= 10
ORDER BY
    rm.production_year DESC, 
    rm.title ASC;
