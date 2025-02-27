WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
TitleInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(CAST(SUM(mi.info IS NOT NULL) AS INTEGER), 0) AS info_count,
        COALESCE(CAST(SUM(CASE WHEN mi.info LIKE '%blockbuster%' THEN 1 ELSE 0 END) AS INTEGER), 0) AS blockbuster_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(cmc.company_count, 0) AS company_count,
    ti.info_count,
    ti.blockbuster_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5' 
        ELSE 'Others' 
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCounts cmc ON rm.movie_id = cmc.movie_id
LEFT JOIN 
    TitleInfo ti ON rm.movie_id = ti.movie_id
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
LIMIT 50;
