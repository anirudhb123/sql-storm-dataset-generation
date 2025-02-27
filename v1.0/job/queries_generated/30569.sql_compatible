
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')
),
ranked_actors AS (
    SELECT 
        ca.movie_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY COUNT(DISTINCT ca.id) DESC) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id, ak.name
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT r.actor_rank) AS unique_actors_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        ranked_actors r ON mh.movie_id = r.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(tm.unique_actors_count, 0) AS unique_actors_count,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    top_movies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
WHERE 
    tm.production_year >= 2000
GROUP BY 
    tm.movie_title, tm.production_year, tm.unique_actors_count
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    unique_actors_count DESC, tm.production_year DESC;
