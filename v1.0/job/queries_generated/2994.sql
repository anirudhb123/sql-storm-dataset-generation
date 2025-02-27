WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
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
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.keywords,
    CASE 
        WHEN f.actor_count > 10 THEN 'Ensemble Cast'
        WHEN f.actor_count IS NOT NULL THEN 'Standard Cast'
        ELSE 'No Cast Information'
    END AS cast_description
FROM 
    FinalResults f
ORDER BY 
    f.production_year DESC, 
    f.actor_count DESC;
