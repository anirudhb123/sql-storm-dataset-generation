WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_data AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Synopsis' THEN mi.info END) AS synopsis,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.cast_names,
        mid.synopsis,
        mid.rating
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        movie_info_data mid ON mh.movie_id = mid.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.total_cast, 0) AS total_cast,
    COALESCE(fm.synopsis, 'No synopsis available') AS synopsis,
    COALESCE(fm.rating, 'Not rated') AS rating,
    STRING_AGG(DISTINCT cmt.kind, ', ') AS company_types
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_type cmt ON mc.company_type_id = cmt.id
WHERE 
    fm.production_year >= 2000
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.total_cast, fm.synopsis, fm.rating
ORDER BY 
    fm.production_year DESC, fm.title;
