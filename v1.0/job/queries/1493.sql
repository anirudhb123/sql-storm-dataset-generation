WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorNames AS (
    SELECT 
        a.person_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.roles_assigned,
        ROW_NUMBER() OVER (ORDER BY md.actor_count DESC) AS rn
    FROM 
        MovieDetails md
    WHERE 
        md.actor_count > 0
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(an.actor_names, 'No actors assigned') AS actors,
    tm.actor_count,
    tm.roles_assigned
FROM 
    TopMovies tm
LEFT JOIN 
    ActorNames an ON tm.movie_id = an.person_id
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC;
