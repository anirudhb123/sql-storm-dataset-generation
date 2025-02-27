WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.name, t.id, t.title, t.production_year, ct.kind
), ActorCounts AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(DISTINCT title_id) AS total_movies,
        STRING_AGG(DISTINCT keywords, '; ') AS all_keywords
    FROM 
        ActorMovies
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    actor_id,
    actor_name,
    total_movies,
    all_keywords
FROM 
    ActorCounts
ORDER BY 
    total_movies DESC
LIMIT 10;
