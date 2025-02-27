WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 

    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rn
    FROM 
        movie_hierarchy mh
),
selected_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.depth
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn <= 5
)
SELECT 
    sm.title,
    sm.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS description,
    CASE 
        WHEN sm.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(sm.production_year AS TEXT)
    END AS production_year_str
FROM 
    selected_movies sm
LEFT JOIN 
    cast_info ci ON sm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON sm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON sm.movie_id = mi.movie_id
GROUP BY 
    sm.movie_id, sm.title, sm.production_year, sm.depth
ORDER BY 
    sm.depth, sm.production_year DESC;
