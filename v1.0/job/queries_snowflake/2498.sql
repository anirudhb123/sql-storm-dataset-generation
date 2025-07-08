
WITH MovieDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY at.production_year DESC) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        at.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(actor_id) AS actor_count
    FROM 
        MovieDetails
    WHERE 
        role_rank = 1
    GROUP BY 
        movie_title, production_year
    ORDER BY 
        actor_count DESC
    LIMIT 5
),
MovieKeywords AS (
    SELECT 
        at.title AS movie_title,
        k.keyword AS movie_keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(mk.movie_keyword, 'No Keywords') AS movie_keyword,
    COUNT(DISTINCT md.actor_id) AS unique_actors,
    LISTAGG(DISTINCT md.actor_name, ', ') WITHIN GROUP (ORDER BY md.actor_name) AS actor_names
FROM 
    TopMovies tm
LEFT JOIN 
    MovieDetails md ON tm.movie_title = md.movie_title AND tm.production_year = md.production_year
LEFT JOIN 
    MovieKeywords mk ON tm.movie_title = mk.movie_title
GROUP BY 
    tm.movie_title, tm.production_year, mk.movie_keyword
HAVING 
    COUNT(DISTINCT md.actor_id) > 2
ORDER BY 
    tm.production_year DESC, unique_actors DESC;
