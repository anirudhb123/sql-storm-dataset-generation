WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        t.title AS parent_title,
        m2.title AS linked_title,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    LEFT JOIN aka_title m2 ON ml.linked_movie_id = m2.id
    LEFT JOIN kind_type t ON m.kind_id = t.id
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        t.title AS parent_title,
        m2.title AS linked_title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    LEFT JOIN kind_type t ON m.kind_id = t.id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(mh.linked_title) OVER(PARTITION BY mh.movie_id) AS linked_count,
        ROW_NUMBER() OVER(ORDER BY mh.production_year DESC, mh.title) AS rank
    FROM 
        movie_hierarchy mh
),
movie_with_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(minfo.info, 'No info available') AS movie_info,
        rm.linked_count,
        rm.rank
    FROM 
        ranked_movies rm
    LEFT JOIN movie_info minfo ON rm.movie_id = minfo.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    mw.title AS Movie_Title,
    mw.production_year AS Production_Year,
    mw.movie_info AS Movie_Info,
    mw.linked_count AS Linked_Movies_Count,
    CASE 
        WHEN mw.production_year < 2000 THEN 'Classic'
        WHEN mw.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS Movie_Era
FROM 
    movie_with_info mw
WHERE 
    mw.linked_count > 0
ORDER BY 
    mw.production_year DESC, 
    mw.title;
