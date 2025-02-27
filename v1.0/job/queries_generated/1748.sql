WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
NamesWithMovies AS (
    SELECT 
        an.name,
        rm.title,
        rm.production_year
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.title_id
),
FilteredNames AS (
    SELECT 
        name,
        COUNT(*) AS movie_count
    FROM 
        NamesWithMovies
    WHERE 
        name IS NOT NULL
    GROUP BY 
        name
    HAVING 
        COUNT(*) > 1
)
SELECT 
    fn.name,
    fn.movie_count,
    STRING_AGG(DISTINCT rn.title, ', ') AS titles
FROM 
    FilteredNames fn
LEFT JOIN 
    NamesWithMovies rn ON fn.name = rn.name
GROUP BY 
    fn.name, fn.movie_count
ORDER BY 
    fn.movie_count DESC;
