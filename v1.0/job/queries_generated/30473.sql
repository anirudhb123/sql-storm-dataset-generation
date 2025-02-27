WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),

filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.kind_id,
        ROW_NUMBER() OVER(PARTITION BY mh.production_year ORDER BY mh.movie_title) AS rn,
        COUNT(*) OVER(PARTITION BY mh.production_year) AS total_movies
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.level = 2
),

movie_info_with_keywords AS (
    SELECT 
        fm.movie_id,
        fm.movie_title,
        fm.production_year,
        fm.kind_id,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords
    FROM 
        filtered_movies fm
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.movie_id, fm.movie_title, fm.production_year, fm.kind_id
)

SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.kind_id,
    mi.keywords,
    CASE 
        WHEN mi.production_year < 2010 THEN 'Before 2010'
        WHEN mi.production_year BETWEEN 2010 AND 2015 THEN '2010-2015'
        ELSE 'After 2015'
    END AS production_period,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info m WHERE m.movie_id = mi.movie_id AND m.info_type_id = 1 AND m.info LIKE '%blockbuster%') 
        THEN 'Blockbuster'
        ELSE 'Not Blockbuster'
    END AS blockbuster_status,
    NULLIF(mi.keywords, 'No Keywords') AS keywords_or_null
FROM 
    movie_info_with_keywords mi
WHERE 
    mi.total_movies > 5
ORDER BY 
    mi.production_year DESC, 
    mi.movie_title;
