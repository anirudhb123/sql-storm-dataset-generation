WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.year_rank <= 10
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
NullCheckTitles AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(mi.info, 'No Info Available') AS info,
        CASE
            WHEN m.cast_count IS NULL THEN 'Missing' 
            ELSE 'Available'
        END AS cast_availability
    FROM 
        FilteredMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.note IS NULL
)
SELECT 
    n.name AS actor_name,
    COUNT(DISTINCT ft.title) AS total_movies,
    AVG(COALESCE(ft.cast_count, 0)) AS avg_cast
FROM 
    aka_name n
LEFT JOIN 
    cast_info c ON n.person_id = c.person_id
LEFT JOIN 
    NullCheckTitles ft ON c.movie_id = ft.movie_id
WHERE 
    n.name IS NOT NULL
    AND n.name NOT LIKE '%[0-9]%' 
GROUP BY 
    n.name
HAVING 
    AVG(COALESCE(ft.cast_count, 0)) > 5
ORDER BY 
    total_movies DESC;
