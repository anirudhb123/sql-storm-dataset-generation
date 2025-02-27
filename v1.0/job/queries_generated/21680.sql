WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), 
CompanyStats AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), 
MovieKeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(cs.company_count, 0) AS total_companies,
    COALESCE(mks.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN COALESCE(mks.keyword_count, 0) > 0 THEN TRUE 
        ELSE FALSE 
    END AS has_keywords,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'Unknown'
        WHEN ac.actor_count > 10 THEN 'Large Cast'
        WHEN ac.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    CompanyStats cs ON rm.title_id = cs.movie_id
LEFT JOIN 
    MovieKeywordStats mks ON rm.title_id = mks.movie_id
WHERE 
    (rm.production_year >= 2000 
    OR rm.title LIKE '%Action%' 
    OR rm.title LIKE '%Drama%')
    AND (rm.production_year IS NOT NULL OR rm.title IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
