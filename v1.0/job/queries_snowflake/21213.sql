WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

MovieActors AS (
    SELECT 
        ci.movie_id,
        a.name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM cast_info ci2 WHERE ci2.movie_id = ci.movie_id AND ci2.nr_order < ci.nr_order)
),

KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

FinalOutput AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ma.name AS actor_name,
        ma.actor_order,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        rm.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieActors ma ON rm.movie_id = ma.movie_id
    LEFT JOIN 
        KeywordCounts kc ON rm.movie_id = kc.movie_id
    WHERE 
        rm.year_rank <= 5
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.actor_order,
    f.keyword_count,
    f.company_count
FROM 
    FinalOutput f
WHERE 
    f.keyword_count IS NOT NULL
    AND (f.keyword_count > 0 OR f.company_count > 1)
ORDER BY 
    f.production_year DESC,
    f.company_count DESC,
    f.actor_order ASC;