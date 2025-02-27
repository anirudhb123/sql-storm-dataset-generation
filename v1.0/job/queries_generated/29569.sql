WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM title m
    JOIN cast_info c ON m.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY m.id, m.title, m.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(co.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mii.info, '; ') AS info
    FROM movie_info mi
    JOIN movie_info_idx mii ON mi.movie_id = mii.movie_id
    GROUP BY mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    mk.keywords,
    mc.companies,
    mi.info
FROM RankedMovies rm
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
ORDER BY rm.production_year DESC, rm.actor_count DESC;
