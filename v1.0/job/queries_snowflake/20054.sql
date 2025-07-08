WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COALESCE(t.season_nr, 0) AS season,
        COALESCE(t.episode_nr, 0) AS episode
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastStatistics AS (
    SELECT  
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS distinct_cast_count,
        SUM(CASE WHEN r.role = 'Lead' THEN 1 ELSE 0 END) AS lead_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyWithCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.title_rank,
    cs.distinct_cast_count,
    cs.lead_count,
    COALESCE(cc.company_count, 0) AS company_count,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category,
    ROW_NUMBER() OVER (PARTITION BY rm.title_rank ORDER BY rm.production_year) AS row_num,
    (SELECT COUNT(*) FROM aka_title at WHERE at.production_year = rm.production_year) AS total_movies_in_year
FROM 
    RankedMovies rm
LEFT JOIN 
    CastStatistics cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    CompanyWithCount cc ON rm.movie_id = cc.movie_id
WHERE 
    (rm.production_year >= 1990) 
AND 
    (cs.lead_count IS NOT NULL OR cc.company_count IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank ASC;
