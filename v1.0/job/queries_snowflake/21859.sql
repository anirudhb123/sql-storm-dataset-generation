
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t1.id AS movie_id,
        t1.title AS movie_title,
        t2.production_year,
        COALESCE(t3.kind, 'Unknown') AS kind,
        1 AS level
    FROM 
        aka_title t1
    LEFT JOIN 
        aka_title t2 ON t1.episode_of_id = t2.id
    LEFT JOIN 
        kind_type t3 ON t1.kind_id = t3.id

    UNION ALL

    SELECT 
        t1.id AS movie_id,
        CONCAT(t2.movie_title, ' -> ', t1.title) AS movie_title,
        t2.production_year,
        COALESCE(t3.kind, 'Unknown') AS kind,
        level + 1
    FROM 
        aka_title t1
    JOIN 
        movie_hierarchy t2 ON t1.episode_of_id = t2.movie_id
    LEFT JOIN 
        kind_type t3 ON t1.kind_id = t3.id
),

featured_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.kind,
        ROW_NUMBER() OVER (PARTITION BY mh.kind ORDER BY mh.production_year DESC) AS rn
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.production_year IS NOT NULL
),

movie_cast_info AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(aka.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name aka ON c.person_id = aka.person_id
    GROUP BY 
        c.movie_id
),

final_output AS (
    SELECT 
        fm.movie_id,
        fm.movie_title,
        fm.production_year,
        fm.kind,
        COALESCE(mci.total_cast, 0) AS total_cast_count,
        COALESCE(mci.cast_names, 'No Cast') AS cast_details
    FROM 
        featured_movies fm
    LEFT JOIN 
        movie_cast_info mci ON fm.movie_id = mci.movie_id
    WHERE 
        fm.rn <= 5 
    ORDER BY 
        fm.kind, fm.production_year DESC
)

SELECT 
    *,
    CASE 
        WHEN total_cast_count = 0 THEN 'No Cast Available'
        ELSE 'Total Cast: ' || total_cast_count
    END AS cast_summary
FROM 
    final_output
WHERE 
    CAST(production_year AS INTEGER) > 2000 
    AND kind NOT LIKE '%Documentary%'
ORDER BY 
    kind, total_cast_count DESC;
