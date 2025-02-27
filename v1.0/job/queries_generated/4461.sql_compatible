
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS actor_count,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies 
    WHERE 
        actor_count <= 10
),
ActorDetails AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.nr_order = 1 AND a.name IS NOT NULL
    GROUP BY 
        a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    mk.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    ActorDetails ad ON tm.movie_id = ad.movie_count
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    (ad.movie_count IS NULL OR ad.movie_count > 2)
    AND mk.keywords IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    ad.movie_count DESC;
