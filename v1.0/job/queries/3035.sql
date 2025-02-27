WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    ),
FilteredCompanies AS (
    SELECT 
        c.id AS company_id, 
        c.name,
        ct.kind AS company_type,
        COUNT(m.movie_id) AS num_movies
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        c.id, c.name, ct.kind
    HAVING 
        COUNT(m.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    fc.name AS company_name,
    fc.company_type,
    fc.num_movies,
    (SELECT 
        AVG(mr.production_year) 
     FROM 
        RankedMovies mr 
     WHERE 
        mr.production_year = rm.production_year) AS avg_year_for_same_year,
    CASE 
        WHEN fc.name IS NOT NULL THEN 'Company Exists' 
        ELSE 'No Company Data' 
    END AS company_status
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCompanies fc ON rm.movie_id = fc.company_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title;
