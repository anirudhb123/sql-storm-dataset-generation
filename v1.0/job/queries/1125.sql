WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), ActorDetails AS (
    SELECT 
        p.name AS actor_name,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.title ORDER BY p.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        aka_title a ON ci.movie_id = a.id
), MoviesWithKeywords AS (
    SELECT 
        m.title,
        k.keyword,
        m.production_year
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    r.title,
    r.production_year,
    r.num_actors,
    COALESCE(STRING_AGG(DISTINCT d.actor_name, ', '), 'No Actors') AS actors,
    COALESCE(STRING_AGG(DISTINCT kw.keyword, ', '), 'No Keywords') AS keywords
FROM 
    RankedMovies r
LEFT JOIN 
    ActorDetails d ON r.title = d.title AND r.production_year = d.production_year
LEFT JOIN 
    MoviesWithKeywords kw ON r.title = kw.title AND r.production_year = kw.production_year
WHERE 
    r.rank <= 5
GROUP BY 
    r.title, r.production_year, r.num_actors
ORDER BY 
    r.production_year DESC, r.num_actors DESC;
