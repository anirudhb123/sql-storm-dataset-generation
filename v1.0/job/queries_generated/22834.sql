WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS title_rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cms.company_count, 0) AS production_companies,
    COALESCE(cms.company_names, 'None') AS companies_involved,
    tm.cast_count,
    'Top-' || tm.cast_count || ' ' || 
        CASE 
            WHEN tm.cast_count = 0 THEN 'no cast members'
            WHEN tm.cast_count = 1 THEN 'single star'
            ELSE 'ensemble cast'
        END AS cast_description,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.title_id AND ci.note IS NOT NULL) AS non_null_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovieStats cms ON cms.movie_id = tm.title_id
WHERE 
    EXISTS (SELECT 1 FROM aka_name an WHERE an.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.title_id))
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
