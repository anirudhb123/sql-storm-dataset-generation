WITH movie_data AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.id) AS role_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        a.name, t.title, t.production_year
),
ranked_movies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        role_count,
        notes_count,
        RANK() OVER (PARTITION BY actor_name ORDER BY role_count DESC, production_year DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    rm.role_count,
    rm.notes_count,
    (SELECT COUNT(DISTINCT tc.title) 
     FROM title tc 
     JOIN movie_keyword mk ON tc.id = mk.movie_id 
     WHERE mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%') 
     AND tc.production_year = rm.production_year) AS action_movie_count,
    COALESCE((SELECT GROUP_CONCAT(DISTINCT company_name.name) 
               FROM movie_companies mc 
               JOIN company_name ON mc.company_id = company_name.id 
               WHERE mc.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = (SELECT person_id FROM aka_name WHERE name = rm.actor_name))),
               'No Production Companies') AS production_companies
FROM 
    ranked_movies rm
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC;
