WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
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
        title,
        production_year,
        company_name,
        keyword
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
)
SELECT 
    f.title,
    f.production_year,
    f.company_name,
    f.keyword,
    COUNT(*) OVER (PARTITION BY f.keyword) AS keyword_count
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.title;
