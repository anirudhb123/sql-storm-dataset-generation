
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM title t
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(DISTINCT c.nr_order) AS total_roles
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type rt ON c.role_id = rt.id
    GROUP BY c.movie_id, a.name, rt.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    ar.total_roles
FROM RankedMovies rm
LEFT JOIN ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_per_year <= 5 AND 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    ar.total_roles DESC, 
    rm.title;
