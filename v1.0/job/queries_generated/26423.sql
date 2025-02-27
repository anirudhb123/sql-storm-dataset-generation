WITH RecursiveMovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        c.kind AS role_type,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, a.name, a.id, c.kind
    ORDER BY 
        t.production_year DESC
), 
ActorPerformance AS (
    SELECT 
        actor_id,
        COUNT(*) AS total_movies,
        STRING_AGG(DISTINCT title, ', ') AS movie_titles,
        MIN(production_year) AS first_appearance,
        MAX(production_year) AS last_appearance
    FROM 
        RecursiveMovieDetails
    GROUP BY 
        actor_id
)
SELECT 
    ap.actor_id,
    a.name AS actor_name,
    ap.total_movies,
    ap.movie_titles,
    ap.first_appearance,
    ap.last_appearance,
    array_agg(DISTINCT m.title) as related_movies
FROM 
    ActorPerformance ap
JOIN 
    aka_name a ON ap.actor_id = a.id
LEFT JOIN 
    complete_cast cc ON a.id = cc.subject_id
LEFT JOIN 
    aka_title m ON cc.movie_id = m.id
WHERE 
    ap.total_movies > 2
GROUP BY 
    ap.actor_id, a.name, ap.total_movies, ap.first_appearance, ap.last_appearance
ORDER BY 
    ap.total_movies DESC, ap.first_appearance;
