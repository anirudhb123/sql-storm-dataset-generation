WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        c.kind AS company_type,
        COUNT(DISTINCT mca.company_id) AS company_count
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        movie_companies mca ON t.id = mca.movie_id
    JOIN 
        company_type c ON mca.company_type_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year, c.kind
), 
TopRankedMovies AS (
    SELECT 
        title,
        production_year,
        company_type,
        company_count,
        RANK() OVER (PARTITION BY company_type ORDER BY company_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tr.title,
    tr.production_year,
    tr.company_type,
    tr.company_count
FROM 
    TopRankedMovies tr
WHERE 
    tr.rank <= 5
ORDER BY 
    tr.company_type, tr.company_count DESC;
