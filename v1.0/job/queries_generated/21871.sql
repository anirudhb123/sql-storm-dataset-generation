WITH Recursive MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 'Unknown Year') AS production_year,
        m.kind_id,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        COALESCE(m.production_year, 'Unknown Year') AS production_year,
        m.kind_id,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

ActorRoles AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        c.movie_id,
        r.role AS role_title,
        ROW_NUMBER() OVER(PARTITION BY ac.movie_id ORDER BY r.role) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
    WHERE 
        ak.name IS NOT NULL
),

MovieDTO AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ar.actor_id) AS cast_count,
        STRING_AGG(DISTINCT ar.actor_name, ', ') AS actor_names,
        RANK() OVER(ORDER BY COUNT(DISTINCT ar.actor_id) DESC) AS cast_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles ar ON mh.movie_id = ar.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

FinalOutput AS (
    SELECT 
        md.*,
        CASE 
            WHEN md.cast_count > 10 THEN 'Large Cast'
            WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_category,
        CASE 
            WHEN md.cast_rank = 1 THEN 'Top Movie'
            ELSE 'Regular Movie'
        END AS movie_status
    FROM 
        MovieDTO md
)

SELECT 
    fo.title,
    fo.production_year,
    fo.actor_names,
    fo.cast_count,
    fo.cast_category,
    fo.movie_status
FROM 
    FinalOutput fo
WHERE 
    fo.production_year != 'Unknown Year'
ORDER BY 
    fo.cast_count DESC, 
    fo.title ASC
LIMIT 50;
