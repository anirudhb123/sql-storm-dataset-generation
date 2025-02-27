WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),
company_movies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
actor_movie_count AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        movie_actors
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_title) > 5
),
ranked_movies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY production_year DESC) AS rank
    FROM 
        movie_actors
)
SELECT 
    am.actor_name,
    COUNT(DISTINCT cm.movie_id) AS company_movies_count,
    AVG(rm.production_year) AS avg_production_year,
    ARRAY_AGG(DISTINCT rm.movie_title ORDER BY rm.rank) AS movies
FROM 
    actor_movie_count am
LEFT JOIN 
    ranked_movies rm ON am.actor_name = rm.actor_name
LEFT JOIN 
    company_movies cm ON rm.movie_title IN (SELECT title FROM aka_title WHERE movie_id = cm.movie_id)
GROUP BY 
    am.actor_name
ORDER BY 
    company_movies_count DESC, avg_production_year DESC
LIMIT 10;
