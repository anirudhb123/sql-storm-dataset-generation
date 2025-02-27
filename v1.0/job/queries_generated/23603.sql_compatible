
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS total_titles
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
), 

ActorRoles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles,
        STRING_AGG(DISTINCT r.role, ', ') AS roles_combined
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),

MovieCompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),

TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.unique_roles, 0) AS role_count,
        COALESCE(mc.company_count, 0) AS company_count,
        COALESCE(tk.keyword_list, 'No Keywords') AS keywords,
        rm.title_rank,
        rm.total_titles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        MovieCompanyCount mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        TitleKeywords tk ON rm.movie_id = tk.movie_id
)

SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.role_count,
    fb.company_count,
    fb.keywords,
    fb.title_rank,
    fb.total_titles,
    CASE 
        WHEN fb.role_count > 5 THEN 'Highly Casted'
        WHEN fb.role_count BETWEEN 3 AND 5 THEN 'Moderately Casted'
        ELSE 'Low Cast Count'
    END AS casting_classification,
    CASE 
        WHEN fb.production_year IS NULL OR fb.production_year < 1900 THEN 'Early Cinema'
        ELSE 'Modern Era'
    END AS era_classification,
    COALESCE(NULLIF(fb.keywords, 'No Keywords'), 'Unknown Keywords') AS keyword_description
FROM 
    FinalBenchmark fb
WHERE 
    fb.title_rank = 1  
ORDER BY 
    fb.production_year DESC, 
    fb.role_count DESC
LIMIT 100;
