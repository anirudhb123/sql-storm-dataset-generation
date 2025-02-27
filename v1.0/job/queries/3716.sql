WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
HighImpactMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cc.role_count,
        cm.company_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastRoleCounts cc ON rt.title_id = cc.movie_id
    LEFT JOIN 
        CompanyMovieCounts cm ON rt.title_id = cm.movie_id
    WHERE 
        rt.year_rank <= 5 AND (cc.role_count IS NOT NULL OR cm.company_count IS NOT NULL)
)
SELECT 
    hi.title,
    hi.production_year,
    COALESCE(hi.role_count, 0) AS actor_count,
    COALESCE(hi.company_count, 0) AS production_company_count,
    CASE 
        WHEN COALESCE(hi.role_count, 0) > COALESCE(hi.company_count, 0) THEN 'More Actors'
        WHEN COALESCE(hi.role_count, 0) < COALESCE(hi.company_count, 0) THEN 'More Companies'
        ELSE 'Equal'
    END AS actor_vs_company
FROM 
    HighImpactMovies hi
ORDER BY 
    hi.production_year DESC, hi.title;
