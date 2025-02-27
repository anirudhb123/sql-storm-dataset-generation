WITH RECURSIVE title_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        pt.title AS parent_title,
        ARRAY[m.title] AS title_path,
        1 AS level
    FROM 
        aka_title AS m
    LEFT JOIN 
        aka_title AS pt ON m.episode_of_id = pt.id
    WHERE 
        m.production_year >= 2000 

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        pt.title AS parent_title,
        th.title_path || m.title,
        th.level + 1
    FROM 
        aka_title AS m
    JOIN 
        title_hierarchy AS th ON m.episode_of_id = th.movie_id
    WHERE 
        m.production_year >= 2000 
),
top_movies AS (
    SELECT 
        th.movie_id,
        th.title,
        th.production_year,
        th.level,
        COUNT(c.id) AS cast_count
    FROM 
        title_hierarchy AS th
    LEFT JOIN 
        cast_info AS c ON th.movie_id = c.movie_id
    GROUP BY 
        th.movie_id, th.title, th.production_year, th.level
),
ranked_movies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.level,
        tm.cast_count,
        ROW_NUMBER() OVER (PARTITION BY tm.level ORDER BY tm.cast_count DESC) AS rank
    FROM 
        top_movies AS tm
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.level,
    COALESCE(AVG(ri.info::numeric), 0) AS average_rating,
    STRING_AGG(DISTINCT c.id::text, ', ') AS cast_ids,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    ranked_movies AS r
LEFT JOIN 
    movie_info AS mi ON r.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword AS mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info AS c ON c.movie_id = r.movie_id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = r.movie_id
GROUP BY 
    r.movie_id, r.title, r.production_year, r.level
HAVING 
    COUNT(DISTINCT mi.info) > 0 
    AND r.cast_count > 5
ORDER BY 
    r.level ASC, average_rating DESC;

