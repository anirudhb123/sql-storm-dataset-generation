WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
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
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        (SELECT COUNT(DISTINCT mk.keyword) FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        ActorCount ac ON tm.movie_id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.keyword_count,
    CASE 
        WHEN md.actor_count > 10 THEN 'Ensemble Cast'
        WHEN md.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_size_category
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
