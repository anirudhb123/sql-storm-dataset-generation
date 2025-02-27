WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL::text AS parent_title
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title,
        mh.level + 1,
        mh.title AS parent_title
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_stats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(ks.keyword_count, 0) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_stats cs ON t.id = cs.movie_id
    LEFT JOIN 
        keyword_stats ks ON t.id = ks.movie_id
)
SELECT 
    mh.level,
    mh.title AS movie_title,
    md.production_year,
    md.total_cast,
    md.keyword_count,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast'
        WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = md.movie_id AND 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')) AS has_budget_info,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_link ml 
     WHERE 
        ml.movie_id = md.movie_id AND 
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'Similar')) AS similar_movies_count
FROM 
    movie_hierarchy mh
JOIN 
    movie_details md ON mh.movie_id = md.movie_id
ORDER BY 
    mh.level, 
    md.production_year DESC, 
    md.total_cast DESC;
