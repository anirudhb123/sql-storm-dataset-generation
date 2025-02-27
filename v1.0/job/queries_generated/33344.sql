WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mp.name, ''), 'Unknown') AS production_company,
        1 AS level
    FROM
        aka_title mt
    LEFT JOIN
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN
        company_name mp ON mc.company_id = mp.id
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(mp.name, ''), 'Unknown') AS production_company,
        mh.level + 1
    FROM
        aka_title m
    INNER JOIN
        movie_link ml ON m.id = ml.movie_id
    INNER JOIN
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name mp ON mc.company_id = mp.id
    WHERE
        m.production_year IS NOT NULL
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.production_company,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level) AS year_rank,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS year_count
    FROM 
        movie_hierarchy mh
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.production_company,
    rm.year_rank,
    rm.year_count,
    p.info AS additional_info
FROM 
    ranked_movies rm
LEFT JOIN 
    person_info p ON p.person_id = (SELECT ci.person_id 
                                      FROM cast_info ci 
                                      WHERE ci.movie_id = rm.movie_id 
                                      ORDER BY ci.nr_order 
                                      LIMIT 1)
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year, rm.year_rank;
