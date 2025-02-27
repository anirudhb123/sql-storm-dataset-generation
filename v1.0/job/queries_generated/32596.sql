WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title AS movie_title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Filter movies only
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE mh.level < 3  -- Limit depth of hierarchy
),
cast_performance AS (
    SELECT c.movie_id, COUNT(c.person_id) AS cast_count, AVG(NULLIF(m.production_year, 0)) AS average_year
    FROM cast_info c
    JOIN aka_title m ON c.movie_id = m.id
    GROUP BY c.movie_id
),
keyword_summary AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_info_summary AS (
    SELECT mi.movie_id, COUNT(mi.info_type_id) AS info_count
    FROM movie_info mi
    GROUP BY mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(cp.cast_count, 0) AS cast_count,
    COALESCE(kws.keywords, 'None') AS keywords,
    COALESCE(mis.info_count, 0) AS info_count,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        WHEN mh.production_year > 2010 THEN 'Recent'
        ELSE 'Unknown'
    END AS movie_age_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_performance cp ON mh.movie_id = cp.movie_id
LEFT JOIN 
    keyword_summary kws ON mh.movie_id = kws.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    mh.movie_title ASC;
This SQL query aggregates data about movies, their casts, keywords, and related information using recursive CTEs, left joins, aggregated functions, and case statements to categorize movies based on their production year.
