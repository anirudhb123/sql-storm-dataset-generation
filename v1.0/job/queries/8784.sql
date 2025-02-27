WITH MovieDetails AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.kind AS comp_type,
        k.keyword AS movie_keyword
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000 
        AND c.kind IN ('Producer', 'Distributor')
),
TopMovies AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
    HAVING 
        COUNT(DISTINCT actor_name) > 5
)
SELECT 
    md.actor_name,
    tm.movie_title,
    tm.actor_count
FROM 
    MovieDetails md
JOIN 
    TopMovies tm ON md.movie_title = tm.movie_title
ORDER BY 
    tm.actor_count DESC, 
    md.movie_title ASC;
