WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS distinct_persons,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
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
),
CombinedResults AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(pr.distinct_persons, 0) AS actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN pr.actor_names IS NOT NULL THEN pr.actor_names 
            ELSE 'Unknown Actors' 
        END AS actors
    FROM 
        TopMovies tm
    LEFT JOIN 
        PersonRoles pr ON tm.movie_id = pr.movie_id
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    c.movie_id,
    c.title,
    c.production_year,
    c.actor_count,
    c.keywords,
    c.actors,
    CASE 
        WHEN c.actor_count > 10 THEN 'Star-studded'
        WHEN c.actor_count IS NULL THEN 'No Cast Data'
        ELSE 'Moderate Cast'
    END AS cast_category
FROM 
    CombinedResults c
WHERE 
    c.actor_count > 0
ORDER BY 
    c.production_year DESC, c.actor_count DESC;
