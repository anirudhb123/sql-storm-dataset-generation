
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS integer) AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
        
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),

CompanyMovieCount AS (
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

EnhancedMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cmc.company_count, 0) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(CASE WHEN ri.role IS NOT NULL THEN 1.0 ELSE 0.0 END) AS actor_ratio
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CompanyMovieCount cmc ON mh.movie_id = cmc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        role_type ri ON ci.role_id = ri.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, cmc.company_count
)

SELECT 
    emi.title,
    emi.production_year,
    emi.company_count,
    emi.keyword_count,
    emi.actor_ratio,
    ROW_NUMBER() OVER (ORDER BY emi.production_year DESC, emi.title) AS rank
FROM 
    EnhancedMovieInfo emi
WHERE 
    emi.company_count > 0
ORDER BY 
    emi.production_year DESC, 
    emi.keyword_count DESC, 
    emi.title;
