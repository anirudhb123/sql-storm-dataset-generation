WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        r.role AS role_type,
        COUNT(*) OVER (PARTITION BY c.movie_id, r.role ORDER BY c.n_order) AS role_counts
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
HighProfileActors AS (
    SELECT 
        actor_name,
        AVG(role_counts) AS avg_roles
    FROM 
        ActorRoles
    GROUP BY 
        actor_name
    HAVING 
        AVG(role_counts) > 2
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(cn.name, 'Unknown Company') AS production_company,
        SUM(CASE WHEN kw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
        MAX(rm.movie_rank) AS latest_movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        RankedMovies rm ON t.id = rm.title_id
    GROUP BY 
        t.id, t.title, t.production_year, cn.name
)
SELECT 
    md.title,
    md.production_year,
    md.production_company,
    md.keyword_count,
    H.actor_name,
    H.avg_roles
FROM 
    MovieDetails md
LEFT JOIN 
    HighProfileActors H ON md.production_company LIKE '%' || H.actor_name || '%'
WHERE 
    (md.keyword_count > 0 OR md.production_year IS NULL)
  AND 
    (md.latest_movie_rank IS NOT NULL AND md.latest_movie_rank < 5 OR md.production_year BETWEEN 2000 AND 2020)
ORDER BY 
    md.production_year DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
