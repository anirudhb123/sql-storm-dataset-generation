WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        all_actors
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2023
    AND 
        cast_count > 10
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.all_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.cast_count, fm.all_actors
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
