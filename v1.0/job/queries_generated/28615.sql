WITH actor_titles AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
actor_count AS (
    SELECT 
        person_id,
        COUNT(DISTINCT movie_title) AS total_movies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        actor_titles
    GROUP BY 
        person_id
)

SELECT 
    a.person_id,
    n.name AS actor_full_name,
    ac.total_movies,
    ac.keywords,
    ct.kind AS role_type
FROM 
    actor_count ac
JOIN 
    aka_name n ON ac.person_id = n.person_id
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
WHERE 
    ac.total_movies > 10
ORDER BY 
    ac.total_movies DESC, 
    n.name ASC;
