WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
), FilteredMovies AS (
    SELECT 
        title, 
        production_year,
        avg_order,
        production_companies
    FROM 
        RankedMovies
    WHERE 
        production_companies > 1
), DetailedMovies AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.avg_order,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = fm.title)
    GROUP BY 
        fm.title, fm.production_year, fm.avg_order
)

SELECT 
    dm.title,
    dm.production_year,
    dm.avg_order,
    dm.keyword_count,
    COALESCE(NULLIF(dm.keyword_count, 0), 'No Keywords') AS keyword_summary
FROM 
    DetailedMovies dm
ORDER BY 
    dm.production_year DESC, 
    dm.avg_order DESC
LIMIT 10;
