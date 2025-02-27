WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt2.title, 'N/A') AS related_title,
        COALESCE(mt2.production_year, 0) AS related_year,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        aka_title mt2 ON ml.linked_movie_id = mt2.id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mt2.title, 'N/A'),
        COALESCE(mt2.production_year, 0),
        mh.level + 1
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    LEFT JOIN 
        aka_title mt2 ON ml.linked_movie_id = mt2.id
    WHERE 
        mh.level < 3
),
top_movies AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        mt.production_year >= 2010
    GROUP BY 
        mt.id, mt.title, mt.production_year
    HAVING 
        COUNT(c.id) >= 3
),
movie_info_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        kw.keyword,
        mi.info AS movie_note,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY kw.keyword) AS keyword_rank
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
)
SELECT 
    th.title AS top_movie,
    th.production_year,
    mv.title AS related_movie,
    mv.related_year,
    mk.keyword,
    mk.movie_note
FROM 
    top_movies th
LEFT JOIN 
    movie_hierarchy mv ON th.id = mv.movie_id
LEFT JOIN 
    movie_info_with_keywords mk ON th.id = mk.movie_id
WHERE 
    th.rank <= 10
ORDER BY 
    th.production_year DESC, th.title, mv.level;
