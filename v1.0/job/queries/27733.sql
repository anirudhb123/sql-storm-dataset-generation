
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > 0
)

SELECT 
    fm.title,
    fm.production_year,
    fm.keyword,
    fm.cast_count,
    COUNT(DISTINCT ci.person_id) AS unique_actors,
    STRING_AGG(DISTINCT aka.name, ', ') AS actor_names  -- Replaced GROUP_CONCAT with STRING_AGG
FROM 
    FilteredMovies fm
JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
JOIN 
    aka_name aka ON ci.person_id = aka.person_id
WHERE 
    fm.production_year > 2000
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.keyword, fm.cast_count
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
