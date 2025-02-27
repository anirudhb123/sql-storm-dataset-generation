WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) as title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE mc.company_type_id IS NOT NULL
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    md.actor_name,
    md.role_name,
    mk.keywords,
    cd.company_names
FROM RankedMovies rm
LEFT JOIN CastDetails md ON rm.movie_id = md.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.title_rank <= 5
   AND (md.actor_rank IS NULL OR md.actor_rank <= 3)
ORDER BY rm.production_year DESC, rm.title;
