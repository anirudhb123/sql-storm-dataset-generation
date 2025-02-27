WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select top-level movies (i.e., those with no episode_of_id)
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL

    UNION ALL

    -- Recursive case: Join with title to find episodes
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM title e
    JOIN MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        ct.kind AS role_kind,
        mv.title AS movie_title,
        mv.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mv.production_year DESC) AS performance_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title mv ON c.movie_id = mv.id
    JOIN role_type ct ON c.role_id = ct.id
    WHERE a.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        COALESCE(COUNT(DISTINCT ac.actor_name), 0) AS actor_count,
        STRING_AGG(DISTINCT ac.actor_name, ', ') AS actors,
        MAX(CASE WHEN ac.performance_rank = 1 THEN ac.role_kind END) AS top_role
    FROM MovieHierarchy mh
    LEFT JOIN ActorRoles ac ON mh.movie_id = ac.movie_title
    GROUP BY mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.actor_count,
    md.actors,
    md.top_role
FROM MovieDetails md
WHERE md.actor_count > 0 
AND md.production_year BETWEEN 2000 AND 2020
ORDER BY md.production_year DESC, md.actor_count DESC;
