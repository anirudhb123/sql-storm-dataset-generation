WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
DetailedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'Production') AS production_company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ac.actor_count, mk.keyword
)
SELECT 
    dm.title,
    dm.production_year,
    dm.actor_count,
    dm.keyword,
    COALESCE(dm.production_company_count, 0) AS production_company_count,
    CASE 
        WHEN dm.actor_count IS NULL THEN 'No Actors' 
        WHEN dm.actor_count > 10 THEN 'Blockbuster' 
        ELSE 'Indie'
    END AS movie_classification
FROM 
    DetailedMovies dm
WHERE 
    dm.production_year >= 2000
ORDER BY 
    dm.production_year DESC, 
    dm.actor_count DESC;
