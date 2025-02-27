WITH actor_movie_counts AS (
    SELECT 
        n.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name n
    JOIN 
        cast_info ci ON n.person_id = ci.person_id
    GROUP BY 
        n.name
),
top_actors AS (
    SELECT 
        actor_name
    FROM 
        actor_movie_counts
    WHERE 
        movie_count > 5
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
actor_info AS (
    SELECT 
        n.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(ci.nr_order) AS highest_role_order
    FROM 
        aka_name n
    JOIN 
        cast_info ci ON n.person_id = ci.person_id
    WHERE 
        n.name IN (SELECT actor_name FROM top_actors)
    GROUP BY 
        n.name
)
SELECT 
    a.actor_name,
    a.movie_count,
    m.title,
    m.keywords,
    i.gender,
    ci.note AS role_note
FROM 
    actor_info a
JOIN 
    cast_info ci ON a.actor_name = (SELECT n.name FROM aka_name n WHERE n.person_id = ci.person_id)
JOIN 
    movies_with_keywords m ON ci.movie_id = m.movie_id
JOIN 
    name i ON i.id = ci.person_role_id
WHERE 
    a.movie_count > 5
ORDER BY 
    a.movie_count DESC, 
    m.title;
