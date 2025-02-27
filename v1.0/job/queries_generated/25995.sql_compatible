
WITH movie_cast AS (
    SELECT 
        a.title AS movie_title,
        ak.name AS actor_name,
        ak.person_id AS actor_id,
        c.nr_order AS role_order,
        r.role AS role_type
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.production_year >= 2000
),
keyworded_movies AS (
    SELECT 
        m.title AS movie_title,
        k.keyword AS movie_keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
),
company_movies AS (
    SELECT 
        a.title AS movie_title,
        cn.name AS company_name
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
)
SELECT 
    mc.movie_title,
    STRING_AGG(DISTINCT mk.movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cm.company_name, ', ') AS companies,
    STRING_AGG(DISTINCT mc.actor_name || ' (' || mc.role_order || ':' || mc.role_type || ')', ', ') AS cast
FROM 
    movie_cast mc
LEFT JOIN 
    keyworded_movies mk ON mc.movie_title = mk.movie_title
LEFT JOIN 
    company_movies cm ON mc.movie_title = cm.movie_title
GROUP BY 
    mc.movie_title
ORDER BY 
    mc.movie_title;
