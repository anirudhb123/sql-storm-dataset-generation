
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        et.kind_id,
        mh.level + 1
    FROM 
        aka_title et
    INNER JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id 
),
ActorRoleCounts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(ci.nr_order) AS first_role_order
    FROM 
        cast_info ci
    JOIN 
        MovieHierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        ak.name,
        ar.movie_count,
        ar.first_role_order,
        ROW_NUMBER() OVER (ORDER BY ar.movie_count DESC) AS rank
    FROM 
        aka_name ak
    JOIN 
        ActorRoleCounts ar ON ak.person_id = ar.person_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    ta.name,
    ta.movie_count,
    ta.first_role_order,
    mh.title AS movie_title,
    mh.production_year,
    CASE 
        WHEN ta.movie_count > 5 THEN 'Frequent Actor'
        WHEN ta.movie_count BETWEEN 3 AND 5 THEN 'Regular Actor'
        ELSE 'Occasional Actor' 
    END AS actor_category
FROM 
    TopActors ta
LEFT JOIN 
    MovieHierarchy mh ON ta.first_role_order = mh.movie_id
WHERE 
    ta.rank <= 10  
ORDER BY 
    ta.movie_count DESC, ta.name;
