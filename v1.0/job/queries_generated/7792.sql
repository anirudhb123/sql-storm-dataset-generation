WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        company_name, 
        keyword
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    fm.movie_id, 
    fm.title, 
    fm.production_year, 
    fm.company_name, 
    COUNT(*) OVER (PARTITION BY fm.production_year) AS total_movies_per_year
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.title;
