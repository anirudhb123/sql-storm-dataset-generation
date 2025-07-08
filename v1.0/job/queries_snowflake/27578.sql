
WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.name, t.title, t.production_year
),

FilteredMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY production_year DESC) AS rn
    FROM 
        ActorMovies
    WHERE 
        production_year >= 2000
)

SELECT 
    f.actor_id,
    f.actor_name,
    CASE 
        WHEN f.rn = 1 THEN 'Latest Movie'
        ELSE 'Earlier Movie'
    END AS movie_type,
    f.movie_title,
    f.production_year,
    f.keywords
FROM 
    FilteredMovies f
WHERE 
    f.rn <= 3
ORDER BY 
    f.actor_id, f.production_year DESC;
