WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mc.company_count, 0) AS company_count,
    rm.actor_names
FROM RankedMovies rm
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY rm.production_year DESC, rm.cast_count DESC;
