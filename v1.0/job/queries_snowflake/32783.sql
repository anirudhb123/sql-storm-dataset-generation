WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
), 
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        MAX(mo.info) AS info_note
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mo ON mh.movie_id = mo.movie_id
    WHERE 
        mo.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(tm.info_note, 'No additional info') AS info_note,
    ROW_NUMBER() OVER (PARTITION BY tm.production_year ORDER BY tm.cast_count DESC) AS rank
FROM 
    top_movies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC
LIMIT 50;