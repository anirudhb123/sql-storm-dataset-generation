WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        COALESCE(mi.info, 'No information available') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.title = mi.info AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
    WHERE 
        rm.year_rank <= 5
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.additional_info,
    STRING_AGG(DISTINCT CONCAT(tc.company_name, '(', tc.company_type, ')'), ', ') AS companies_involved
FROM 
    FilteredMovies fm
LEFT JOIN 
    TopCompanies tc ON fm.title = (SELECT title FROM aka_title WHERE movie_id = tc.movie_id)
GROUP BY 
    fm.title, fm.production_year, fm.actor_count, fm.additional_info
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;
