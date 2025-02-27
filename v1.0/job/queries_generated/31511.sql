WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level,
        ARRAY[t.title] AS title_path
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        m.movie_id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        mh.level + 1 AS level,
        mh.title_path || t.title
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
ActorRoles AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        r.role AS actor_role,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rnk
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        ActorRoles
    WHERE 
        rnk <= 3
    GROUP BY 
        actor_name
)
SELECT 
    mh.movie_title,
    mh.production_year,
    ta.actor_name,
    ta.movie_count,
    CASE 
        WHEN mh.level = 1 THEN 'Original'
        ELSE 'Sequel/Linked'
    END AS movie_type,
    COALESCE(NULLIF(CONCAT('Total Movies: ', ta.movie_count), 'Total Movies: 0'), 'No Movies') AS movie_summary
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopActors ta ON mh.movie_title = ta.actor_name
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.production_year DESC, movie_count DESC;
