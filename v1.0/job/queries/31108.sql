WITH RECURSIVE ActorMovies AS (
    SELECT 
        ca.person_id,
        ta.title,
        ta.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ta.production_year DESC) AS rank
    FROM 
        cast_info ca
    INNER JOIN 
        aka_title ta ON ca.movie_id = ta.id
)

SELECT 
    ak.name AS actor_name,
    COALESCE(string_agg(DISTINCT am.title, ', '), 'No Movies') AS movies,
    COUNT(DISTINCT am.production_year) AS total_years_active,
    MAX(am.production_year) AS last_movie_year,
    CASE 
        WHEN COUNT(DISTINCT am.production_year) > 5 THEN 'Veteran Actor'
        WHEN COUNT(DISTINCT am.production_year) BETWEEN 2 AND 5 THEN 'Intermediate Actor'
        ELSE 'Newcomer'
    END AS actor_experience_level
FROM 
    aka_name ak
LEFT JOIN 
    ActorMovies am ON ak.person_id = am.person_id AND am.rank <= 10
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT am.title) > 0
ORDER BY 
    actor_experience_level DESC, 
    COUNT(DISTINCT am.title) DESC;