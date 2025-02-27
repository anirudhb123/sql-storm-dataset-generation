WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoleCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.total_movies,
        a.roles,
        ROW_NUMBER() OVER (ORDER BY a.total_movies DESC) AS rn
    FROM 
        ActorRoleCount a
    WHERE 
        a.total_movies > 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COUNT(DISTINCT c.id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id AND a.name IS NOT NULL
    GROUP BY 
        t.title, t.production_year, a.name
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ta.roles AS actor_roles,
    COUNT(DISTINCT md.actor_name) AS actors_count,
    AVG(md.total_cast) AS avg_cast_count
FROM 
    MovieHierarchy mh
JOIN 
    TopActors ta ON mh.movie_id = ta.person_id
LEFT JOIN 
    MovieDetails md ON md.production_year = mh.production_year
GROUP BY 
    mh.title, mh.production_year, ta.roles
HAVING 
    COUNT(DISTINCT md.actor_name) > 0
ORDER BY 
    mh.production_year DESC, actors_count DESC;
