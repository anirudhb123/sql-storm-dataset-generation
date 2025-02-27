WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
)
, cast_details AS (
    SELECT 
        ca.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id
)
, movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mt.info, '; ') AS info_notes,
        MAX(CASE WHEN it.info = 'Genre' THEN mt.info END) AS genre,
        NULL AS empty_column  -- To showcase NULL logic
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actors,
    cd.actor_count,
    mid.info_notes,
    mid.genre,
    CASE 
        WHEN mid.empty_column IS NULL THEN 'Unknown Info' 
        ELSE mid.empty_column 
    END AS status,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COALESCE(SUM(CASE WHEN mt.kind IN ('Distributor', 'Producer') THEN 1 ELSE 0 END), 0) AS special_company_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS year_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_type mt ON mc.company_type_id = mt.id
LEFT JOIN 
    movie_info_details mid ON mid.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cd.actors, cd.actor_count, mid.info_notes, mid.genre
HAVING 
    COUNT(DISTINCT mc.company_id) > 3 OR MAX(mid.actor_count) > 5
ORDER BY 
    CASE WHEN mid.genre IS NULL THEN 1 ELSE 0 END, mid.genre, mh.production_year DESC, mh.title;
