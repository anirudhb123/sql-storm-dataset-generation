WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS year_count
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ak.id AS aka_id,
        ak.person_id,
        ak.name,
        ci.movie_id,
        ci.nr_order,
        COALESCE(ri.*) AS role_info
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        role_type ri ON ci.role_id = ri.id  
    WHERE 
        ak.name IS NOT NULL
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordsPerMovie AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ad.name AS actor_name,
    ad.nr_order,
    cm.company_names,
    cm.total_companies,
    kp.total_keywords,
    CASE 
        WHEN kp.total_keywords > 0 THEN 'Keywords Available' 
        ELSE 'No Keywords' 
    END AS keyword_status,
    'Rank: ' || rm.year_rank || '/' || rm.year_count AS year_ranking,
    COALESCE(ad.role_info->'role', 'Unknown Role') AS role_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    KeywordsPerMovie kp ON rm.movie_id = kp.movie_id
WHERE 
    (rm.year_rank <= 3 OR ad.name IS NOT NULL)
    AND (LOWER(rm.title) LIKE '%adventure%' OR rm.production_year < 2000)
ORDER BY 
    rm.production_year DESC, 
    COALESCE(ad.nr_order, 999) ASC;
