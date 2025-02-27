WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mk.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rnk,
        COUNT(mk.id) OVER (PARTITION BY mt.id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        ak.name AS actor_name,
        mt.id AS movie_id,
        mt.title,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE 1 END) AS num_roles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    GROUP BY 
        ak.name, mt.id, mt.title
),
PopularKeywords AS (
    SELECT 
        mkt.keyword,
        COUNT(mkt.id) AS usage_count
    FROM 
        movie_keyword mkt
    GROUP BY 
        mkt.keyword
    HAVING 
        COUNT(mkt.id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    ai.actor_name,
    ai.num_roles,
    COALESCE(pkw.usage_count, 0) AS keyword_usage,
    CASE 
        WHEN ai.num_roles > 0 THEN 'Active Actor'
        ELSE 'Inactive Actor'
    END AS activity_status
FROM 
    RankedMovies rm
JOIN 
    ActorsInMovies ai ON rm.movie_id = ai.movie_id
LEFT JOIN 
    PopularKeywords pkw ON rm.keyword = pkw.keyword
WHERE 
    rm.rnk <= 3 
    AND (rm.keyword_count > 2 OR ai.num_roles > 1)
ORDER BY 
    rm.production_year DESC, keyword_usage DESC, ai.actor_name;
