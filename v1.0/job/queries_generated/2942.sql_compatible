
WITH RankedMovies AS (
    SELECT 
        at.title,
        ct.kind AS company_type,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank_title,
        COUNT(mc.movie_id) OVER (PARTITION BY at.id) AS company_count
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        at.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT
        rm.*,
        (CASE 
            WHEN rm.company_count > 1 THEN 'Multiple'
            WHEN rm.company_count = 1 THEN 'Single'
            ELSE 'None'
        END) AS company_status
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_title <= 5
),
FinalOutput AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.company_type,
        fm.company_status, 
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = (
            SELECT 
                id 
            FROM 
                aka_title 
            WHERE 
                title = fm.title AND 
                production_year = fm.production_year 
            LIMIT 1
        )
    GROUP BY 
        fm.title, fm.production_year, fm.company_type, fm.company_status
)

SELECT 
    fo.title,
    fo.production_year,
    fo.company_type,
    fo.company_status,
    COALESCE(total_actors, 0) AS total_actors
FROM 
    FinalOutput fo
WHERE 
    fo.company_status != 'None'
ORDER BY 
    fo.production_year DESC, 
    fo.title;
