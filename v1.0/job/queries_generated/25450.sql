WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        COUNT(*) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000  -- Considering movies produced after year 2000
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
PopularRoles AS (
    SELECT 
        c.role_id,
        r.role AS role_name,
        COUNT(DISTINCT c.person_id) AS distinct_cast_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.role_id, r.role
    HAVING 
        COUNT(DISTINCT c.person_id) > 10  -- Considering roles played by more than 10 different actors
),
MoviesWithPopularRoles AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        pr.role_name,
        pr.distinct_cast_count,
        rm.movie_keyword
    FROM 
        RankedMovies rm
    JOIN 
        cast_info c ON rm.movie_id = c.movie_id
    JOIN 
        PopularRoles pr ON c.role_id = pr.role_id
),
FinalResults AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        STRING_AGG(DISTINCT m.movie_keyword, ', ') AS keywords,
        AVG(m.distinct_cast_count) AS avg_distinct_cast_per_role
    FROM 
        MoviesWithPopularRoles m
    GROUP BY 
        m.movie_id, m.movie_title, m.production_year
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.keywords,
    fr.avg_distinct_cast_per_role
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC,
    fr.avg_distinct_cast_per_role DESC
LIMIT 10;  -- Limiting to top 10 movies

This query benchmarks string processing by retrieving information about movies produced after 2000, along with their popular roles and associated keywords. It aggregates and averages the distinct cast counts for roles, ultimately returning a ranked list based on production year and average distinct cast count per role.
