WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),

CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),

NullHandling AS (
    SELECT 
        t.movie_id,
        COALESCE(cc.company_count, 0) AS company_count,
        CASE 
            WHEN cc.company_count IS NULL THEN 'No Companies'
            WHEN cc.company_count = 0 THEN 'Companyless'
            ELSE 'Has Companies'
        END AS company_status
    FROM 
        RankedMovies t
    LEFT JOIN 
        CompanyCounts cc ON t.movie_id = cc.movie_id
),

StringAggregates AS (
    SELECT 
        n.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT ak.id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        title n ON c.movie_id = n.id
    GROUP BY 
        n.movie_id
)

SELECT 
    t.movie_id,
    t.title, 
    t.production_year,
    t.title_rank,
    nh.company_count,
    nh.company_status,
    sa.actors,
    sa.actor_count
FROM 
    RankedMovies t
JOIN 
    NullHandling nh ON t.movie_id = nh.movie_id
LEFT JOIN 
    StringAggregates sa ON t.movie_id = sa.movie_id
WHERE 
    (objc ON t.production_year = 2021 AND nh.company_count > 3)
    OR (nh.company_status = 'Companyless' AND sa.actor_count < 2)
ORDER BY 
    t.production_year DESC, 
    t.title_rank
FETCH FIRST 10 ROWS ONLY;
