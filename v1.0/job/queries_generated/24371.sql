WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        lt.title, 
        lt.production_year, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

actor_stats AS (
    SELECT 
        ac.person_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT ac.movie_id) AS movie_count,
        AVG(EXTRACT(YEAR FROM m.production_year)) AS avg_production_year
    FROM 
        cast_info ac
    JOIN 
        aka_name a ON ac.person_id = a.person_id
    JOIN 
        aka_title m ON ac.movie_id = m.movie_id
    GROUP BY 
        ac.person_id, a.name
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
),

combined_info AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(ks.keywords, 'No keywords') AS keywords,
        COALESCE(a.actor_name, 'Unknown Actor') AS actor_name,
        COALESCE(a.movie_count, 0) AS actor_movie_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_num
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        actor_stats a ON m.movie_id = a.movie_id
    LEFT JOIN 
        movie_keywords ks ON m.movie_id = ks.movie_id
)

SELECT 
    movie_title, 
    production_year, 
    keywords,
    actor_name, 
    actor_movie_count
FROM 
    combined_info
WHERE 
    row_num <= 5
    OR (actor_movie_count > 3 AND production_year < 2000)
ORDER BY 
    production_year DESC, movie_title ASC;
