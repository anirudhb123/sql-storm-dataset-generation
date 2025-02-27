WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        1 AS depth,
        m.production_year,
        COALESCE(cn.name, 'Unknown Company') AS production_company
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id

    UNION ALL

    SELECT
        m.id,
        m.title,
        mh.depth + 1,
        m.production_year,
        COALESCE(cn.name, 'Unknown Company') AS production_company
    FROM
        movie_hierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    mh.production_company,
    CASE 
        WHEN mh.production_year IS NULL THEN 'N/A' 
        ELSE CAST(mh.production_year AS TEXT) 
    END AS formatted_year,
    ROW_NUMBER() OVER (PARTITION BY mh.production_company ORDER BY mh.production_year DESC) AS company_rank,
    COUNT(*) OVER (PARTITION BY mh.production_company) AS movie_count,
    SUM(CASE WHEN mh.depth > 1 THEN 1 ELSE 0 END) OVER (PARTITION BY mh.production_company) AS linked_movies_count
FROM 
    movie_hierarchy mh
WHERE 
    mh.production_company NOT LIKE '%Unknown%'
    AND mh.depth <= 3
    AND mh.movie_id NOT IN (SELECT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Documentary'))
ORDER BY 
    mh.production_company, mh.production_year DESC;
