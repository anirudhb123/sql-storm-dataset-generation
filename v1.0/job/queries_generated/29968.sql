WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.nickname AS actor_nickname,
        GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = cc.subject_id
    GROUP BY 
        t.title, t.production_year, ak.name, ak.nickname
),
actor_role AS (
    SELECT 
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        ak.name, rt.role
),
popular_movies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(*) AS actor_count
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year
    HAVING 
        COUNT(*) > 1
)
SELECT 
    dm.movie_title,
    dm.production_year,
    dm.movie_keywords,
    ar.actor_name,
    ar.role_name,
    ar.role_count,
    pm.actor_count
FROM 
    movie_details dm
JOIN 
    actor_role ar ON ar.actor_name = dm.actor_name
JOIN 
    popular_movies pm ON pm.movie_title = dm.movie_title
ORDER BY 
    dm.production_year DESC, 
    pm.actor_count DESC;
