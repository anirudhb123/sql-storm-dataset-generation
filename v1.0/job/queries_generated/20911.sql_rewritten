WITH RecursiveActorMovies AS (
    SELECT 
        c.person_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.nr_order < 5 
),
LatestMovies AS (
    SELECT 
        ram.person_id,
        ram.movie_title,
        ram.production_year,
        COUNT(DISTINCT pa.person_id) AS coactors_count
    FROM 
        RecursiveActorMovies ram
    LEFT JOIN 
        cast_info cii ON ram.movie_title = (SELECT title FROM aka_title WHERE id = cii.movie_id)
    LEFT JOIN 
        cast_info pa ON cii.movie_id = pa.movie_id AND pa.person_id <> ram.person_id
    WHERE 
        ram.rn = 1
    GROUP BY 
        ram.person_id, ram.movie_title, ram.production_year
),
ActorsWithMultiRoles AS (
    SELECT 
        ak.name AS actor_name,
        la.movie_title,
        la.production_year,
        la.coactors_count,
        (SELECT COUNT(*) FROM cast_info WHERE person_id = ak.person_id) AS total_roles
    FROM 
        aka_name ak
    JOIN 
        LatestMovies la ON ak.person_id = la.person_id
    WHERE 
        la.coactors_count > 3 
),
FilteredActors AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY coactors_count DESC) AS actor_rank
    FROM 
        ActorsWithMultiRoles
    WHERE 
        total_roles >= 3 
)
SELECT 
    fa.actor_name,
    fa.movie_title,
    fa.production_year,
    fa.coactors_count,
    fa.actor_rank
FROM 
    FilteredActors fa
WHERE 
    fa.actor_rank <= 5 
ORDER BY 
    fa.production_year DESC,
    fa.coactors_count DESC;