WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(ak.name, '(', r.role, ')'), ', ') AS cast_list
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.rank_year,
        rm.cast_count,
        rm.cast_list
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
)

SELECT 
    f.title,
    f.production_year,
    COALESCE(f.cast_list, 'No cast available') AS cast,
    CASE
        WHEN f.rank_year < 5 THEN 'Recent Release'
        ELSE 'Older Release'
    END AS release_category
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC;

SELECT 
    COUNT(*) AS total_movies
FROM 
    aka_title a
WHERE 
    a.production_year > 2000
UNION ALL
SELECT 
    COUNT(DISTINCT c.movie_id) AS total_casted_movies
FROM 
    cast_info c
JOIN 
    aka_title a ON c.movie_id = a.id
WHERE 
    a.production_year > 2000;
