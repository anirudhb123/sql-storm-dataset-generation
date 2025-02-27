WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title ASC) AS rn
    FROM title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvMovie'))
), 
ActorInfo AS (
    SELECT 
        akn.name AS actor_name,
        ci.movie_id,
        mt.production_year,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM cast_info ci
    INNER JOIN aka_name akn ON ci.person_id = akn.person_id
    INNER JOIN title mt ON ci.movie_id = mt.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cd.id) AS company_count,
        MAX(cd.name) AS latest_company_name
    FROM movie_companies mc
    JOIN company_name cd ON mc.company_id = cd.id
    GROUP BY mc.movie_id
)
SELECT 
    DISTINCT rm.title,
    rm.production_year,
    ai.actor_name,
    mc.company_count,
    mc.latest_company_name
FROM RankedMovies rm
LEFT JOIN ActorInfo ai ON rm.movie_id = ai.movie_id
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    (ai.actor_count > 2 OR mc.company_count IS NULL)
    AND (rm.production_year BETWEEN 2000 AND 2020)
    AND (CHAR_LENGTH(rm.title) - CHAR_LENGTH(REPLACE(rm.title, ' ', '')) + 1) > 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
