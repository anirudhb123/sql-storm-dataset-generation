WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT m.company_id) AS company_count, 
        AVG(m.movie_id) AS avg_movie_id
    FROM 
        title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    GROUP BY 
        t.title, 
        t.production_year
    HAVING 
        COUNT(DISTINCT m.company_id) > 1
),
actor_roles AS (
    SELECT 
        a.name AS actor_name, 
        ct.kind AS role_name, 
        C.movie_id
    FROM 
        aka_name a 
    JOIN 
        cast_info C ON a.person_id = C.person_id
    JOIN 
        role_type ct ON C.role_id = ct.id
),
movie_keywords AS (
    SELECT 
        m.movie_id, 
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
)
SELECT 
    rm.title, 
    rm.production_year, 
    ar.actor_name, 
    ar.role_name, 
    mk.keyword, 
    rm.company_count,
    rm.avg_movie_id
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_roles ar ON rm.title = (SELECT t.title FROM title t WHERE t.id = ar.movie_id)
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC, 
    ar.actor_name;
