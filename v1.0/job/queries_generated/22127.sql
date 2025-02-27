WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfoExtended AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(ci.companies, 'Unknown') AS companies,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CompanyInfo ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, ci.companies
),
FinalReport AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.companies,
        m.keyword_count,
        CASE 
            WHEN m.keyword_count > 10 THEN 'High'
            WHEN m.keyword_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS keyword_density
    FROM 
        MovieInfoExtended m
)
SELECT 
    fr.*,
    pi.info AS person_info
FROM 
    FinalReport fr
LEFT JOIN 
    person_info pi ON pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Academy Award')
WHERE 
    fr.production_year >= 2000
    AND (fr.companies IS NOT NULL OR fr.keyword_count > 0)
ORDER BY 
    fr.keyword_count DESC, fr.production_year ASC;
