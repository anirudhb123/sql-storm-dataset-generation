WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(DISTINCT m.id) OVER (PARTITION BY t.production_year) AS movie_count,
        COALESCE(CAST(NULLIF(t.production_year, 2021) AS TEXT), 'N/A') AS year_label
    FROM 
        aka_title t
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
)
, CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
        JOIN aka_name a ON c.person_id = a.person_id
        LEFT JOIN role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order IS NOT NULL
)
, MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    CASE 
        WHEN rm.movie_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_category,
    cd.actor_name,
    cd.role_name,
    mcd.company_count,
    mcd.companies,
    rm.year_label
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    (mcd.company_count > 3 OR cd.actor_name IS NOT NULL)
    AND (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rm.movie_id) > 0
ORDER BY 
    rm.production_year DESC,
    rm.year_rank,
    cd.actor_name
LIMIT 50;
