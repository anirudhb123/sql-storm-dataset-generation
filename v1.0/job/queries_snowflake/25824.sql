
WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year AS year,
        kc.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        a.name ILIKE '%Smith%' 
)

SELECT 
    am.actor_id,
    am.actor_name,
    LISTAGG(am.movie_title || ' (' || am.year || ')', ', ') WITHIN GROUP (ORDER BY am.year DESC) AS movies,
    LISTAGG(DISTINCT am.keyword, ', ') AS keywords,
    COUNT(*) AS movie_count
FROM 
    ActorMovies am
WHERE 
    am.movie_rank <= 3  
GROUP BY 
    am.actor_id, 
    am.actor_name
ORDER BY 
    movie_count DESC;
