
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieStats AS (
    SELECT 
        p.id AS person_id,
        COUNT(c.movie_id) AS movie_count,
        AVG(CASE WHEN t.production_year IS NOT NULL THEN t.production_year ELSE NULL END) AS average_year
    FROM 
        aka_name p
    JOIN 
        cast_info c ON p.person_id = c.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        p.id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CombinedResults AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        a.movie_count,
        a.average_year,
        k.keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorMovieStats a ON r.movie_id = a.person_id
    LEFT JOIN 
        MoviesWithKeywords k ON r.movie_id = k.movie_id
)
SELECT 
    cr.movie_id,
    cr.title,
    COALESCE(cr.production_year, -1) AS production_year,
    COALESCE(cr.movie_count, 0) AS total_actors,
    COALESCE(cr.average_year, 1900) AS average_actor_birth_year,
    COALESCE(cr.keywords, 'No Keywords') AS keywords
FROM 
    CombinedResults cr
WHERE 
    cr.production_year > 2000
    OR (cr.production_year IS NULL AND cr.keywords IS NOT NULL)
ORDER BY 
    cr.production_year DESC NULLS LAST, cr.movie_id
LIMIT 100;
