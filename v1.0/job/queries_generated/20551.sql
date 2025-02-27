WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.title_id
    GROUP BY 
        ci.person_id
),
ActorYearCount AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT rm.production_year) AS distinct_years_active
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.title_id
    GROUP BY 
        a.person_id
),
NullYearActors AS (
    SELECT 
        a.name, 
        a.person_id
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        at.production_year IS NULL
)
SELECT 
    DISTINCT a.name,
    COALESCE(ac.movie_count, 0) AS total_movies,
    COALESCE(ayc.distinct_years_active, 0) AS years_active,
    CASE 
        WHEN ac.movie_count IS NOT NULL AND ayc.distinct_years_active IS NOT NULL THEN 
            round(cast(ac.movie_count AS numeric) / ayc.distinct_years_active, 2)
        ELSE 
            NULL
    END AS avg_movies_per_year,
    CASE 
        WHEN nm.person_id IS NOT NULL THEN 
            'Has null production year films'
        ELSE 
            'Active within production years'
    END AS status
FROM 
    aka_name a
LEFT JOIN 
    ActorMovieCount ac ON a.person_id = ac.person_id
LEFT JOIN 
    ActorYearCount ayc ON a.person_id = ayc.person_id
LEFT JOIN 
    NullYearActors nm ON a.person_id = nm.person_id
ORDER BY 
    total_movies DESC NULLS LAST, years_active DESC;
