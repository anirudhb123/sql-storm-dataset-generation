
WITH movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023  

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_performance AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(cp.total_cast, 0) AS total_cast,
        COALESCE(cp.cast_names, 'No cast') AS cast_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_performance cp ON mh.movie_id = cp.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    CASE 
        WHEN md.total_cast > 10 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_type,
    COUNT(DISTINCT mci.company_id) AS production_companies
FROM 
    movie_details md
LEFT JOIN 
    movie_companies mci ON md.movie_id = mci.movie_id
LEFT JOIN 
    company_name cn ON mci.company_id = cn.id
WHERE 
    md.production_year >= 2000
    AND md.movie_title NOT LIKE '%remake%'
GROUP BY 
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.cast_names
HAVING 
    COUNT(DISTINCT mci.company_id) >= 1
ORDER BY 
    md.production_year DESC,
    md.total_cast DESC;
