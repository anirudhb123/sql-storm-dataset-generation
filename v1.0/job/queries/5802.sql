WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        COUNT(DISTINCT kw.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.company_count,
    fm.keyword_count,
    COUNT(DISTINCT ci.person_id) AS cast_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    complete_cast cc ON fm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.company_count, fm.keyword_count
ORDER BY 
    fm.production_year DESC, fm.company_count DESC, fm.keyword_count DESC;
