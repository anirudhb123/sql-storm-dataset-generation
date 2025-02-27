WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        COUNT(DISTINCT mki.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mki ON t.id = mki.movie_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.company_name,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1 AND rm.keyword_count > 5
)
SELECT 
    f.title, 
    f.production_year, 
    f.company_name, 
    f.keyword_count
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.title ASC;
