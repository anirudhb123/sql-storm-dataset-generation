WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.kind ORDER BY c.kind) AS company_types,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS company_count,
        COUNT(DISTINCT k.id) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.*
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000 AND 
        rm.company_count > 2 AND 
        rm.keyword_count > 3
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.company_types,
    fm.keywords,
    fm.rank
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 50
ORDER BY 
    fm.production_year DESC, fm.title;
