WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rn,
        COUNT(mk.id) OVER (PARTITION BY a.id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
DistinctActors AS (
    SELECT DISTINCT
        ci.person_id,
        an.name
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM RankedMovies WHERE rn <= 5)
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.kind_id,
        dk.name AS actor_name,
        COALESCE(mc.company_count, 0) AS company_count,
        rm.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DistinctActors dk ON rm.id = (
            SELECT MIN(rm2.id)
            FROM RankedMovies rm2
            JOIN cast_info ci ON rm2.id = ci.movie_id
            WHERE ci.person_id = dk.person_id
        )
    LEFT JOIN 
        MovieCompanies mc ON rm.id = mc.movie_id
)
SELECT 
    title,
    production_year,
    kind_id,
    actor_name,
    company_count,
    keyword_count
FROM 
    FinalResults
WHERE 
    (keyword_count > 3 OR actor_name IS NULL)
ORDER BY 
    production_year DESC, kind_id
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
