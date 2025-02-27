WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id AS actor_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT t.title) AS titles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 3
),
movie_stats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(AVG(r.rating), 0) AS average_rating,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        (SELECT movie_id, AVG(CAST(info AS FLOAT)) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) r ON m.id = r.movie_id
    GROUP BY 
        m.id
),
actor_movies AS (
    SELECT 
        ah.actor_id,
        m.movie_id,
        m.title,
        m.average_rating,
        ROW_NUMBER() OVER (PARTITION BY ah.actor_id ORDER BY m.average_rating DESC) AS rank
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ah.actor_id = ci.person_id
    JOIN 
        movie_stats m ON ci.movie_id = m.movie_id
)
SELECT 
    a.id AS actor_id,
    ak.name,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    STRING_AGG(DISTINCT am.title, ', ') AS movie_titles,
    MAX(am.average_rating) AS highest_rating,
    COUNT(DISTINCT ak.name) FILTER (WHERE ak.name IS NOT NULL) AS unique_names,
    MIN(am.average_rating) OVER (PARTITION BY a.id) AS lowest_rating,
    CASE 
        WHEN COUNT(DISTINCT ak.name) FILTER (WHERE ak.name IS NULL) > 0 THEN 'Contains NULL names'
        ELSE 'No NULL names'
    END AS null_name_status
FROM 
    actor_hierarchy a
JOIN 
    aka_name ak ON a.actor_id = ak.person_id
LEFT JOIN 
    actor_movies am ON a.actor_id = am.actor_id
GROUP BY 
    a.id, ak.name
HAVING 
    COUNT(DISTINCT am.movie_id) > 5
ORDER BY 
    total_movies DESC, highest_rating DESC
LIMIT 10;
