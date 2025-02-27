WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(*) OVER (PARTITION BY a.production_year) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM akAS_title a
    WHERE a.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        cmp.name AS company_name,
        cmp.country_code,
        ct.kind AS company_type
    FROM movie_companies m
    JOIN company_name cmp ON m.company_id = cmp.id
    JOIN company_type ct ON m.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    cd.company_name,
    cd.country_code,
    cd.company_type,
    mk.keywords,
    CASE
        WHEN rm.movie_count > 1 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM RankedMovies rm
LEFT JOIN ActorCount ac ON rm.id = ac.movie_id
LEFT JOIN CompanyDetails cd ON rm.id = cd.movie_id
LEFT JOIN MovieKeywords mk ON rm.id = mk.movie_id
WHERE rm.rn = 1
ORDER BY rm.production_year DESC, rm.title ASC
LIMIT 100;
