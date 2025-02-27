WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
HighRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rank_by_cast = 1
),
Persons AS (
    SELECT 
        DISTINCT a.person_id,
        n.name AS actor_name
    FROM 
        cast_info a
    JOIN 
        aka_name n ON a.person_id = n.person_id
    WHERE 
        n.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        h.title,
        h.production_year,
        STRING_AGG(DISTINCT p.actor_name, ', ') AS actors
    FROM 
        HighRankedMovies h
    LEFT JOIN 
        cast_info c ON h.movie_id = c.movie_id
    LEFT JOIN 
        Persons p ON c.person_id = p.person_id
    GROUP BY 
        h.title, h.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No actors listed') AS actors_involved
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC;
