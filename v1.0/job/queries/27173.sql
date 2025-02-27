WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        kt.kind AS movie_kind,
        COUNT(k.id) AS keyword_count
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000 
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        rt.role AS role_name,
        ci.movie_id
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.movie_kind,
        rm.production_year,
        ar.actor_name,
        ar.role_name
    FROM RankedMovies rm
    JOIN ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    md.movie_title,
    md.movie_kind,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name || ' (' || md.role_name || ')', ', ') AS actor_details
FROM MovieDetails md
GROUP BY md.movie_title, md.movie_kind, md.production_year
ORDER BY md.production_year DESC, md.movie_title;