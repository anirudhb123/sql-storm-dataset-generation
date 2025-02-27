WITH MovieActor AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        c.movie_id,
        t.title,
        t.production_year,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),

CompanyMovie AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
),

ActorMovieDetails AS (
    SELECT 
        ma.actor_name,
        ma.actor_id,
        ma.movie_id,
        ma.title,
        ma.production_year,
        cm.company_names,
        cm.company_types,
        ma.actor_count
    FROM 
        MovieActor ma
    LEFT JOIN 
        CompanyMovie cm ON ma.movie_id = cm.movie_id
)

SELECT 
    amd.actor_name,
    amd.title,
    amd.production_year,
    amd.company_names,
    amd.company_types,
    amd.actor_count
FROM 
    ActorMovieDetails amd
WHERE 
    amd.actor_count > 2
ORDER BY 
    amd.production_year DESC, amd.actor_name;
