WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.season_nr IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id, 
        et.title, 
        et.production_year, 
        mh.depth + 1
    FROM 
        aka_title et
    JOIN 
        movie_link ml ON et.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        ci.nr_order, 
        rt.role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
NamedActors AS (
    SELECT 
        ak.name AS actor_name,
        ar.movie_id,
        COUNT(*) OVER (PARTITION BY ar.movie_id) AS actor_count
    FROM 
        ActorRoles ar
    JOIN 
        aka_name ak ON ar.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year, 
        COALESCE(na.actor_count, 0) AS actor_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        NamedActors na ON mh.movie_id = na.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    CASE 
        WHEN fm.actor_count > 5 THEN 'Large Cast'
        WHEN fm.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    ARRAY_AGG(DISTINCT CONCAT('Year: ', fm.production_year, ', Cast: ', fm.actor_count)) OVER (ORDER BY fm.production_year) AS cast_summary
FROM 
    FilteredMovies fm
WHERE 
    fm.actor_count IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC
LIMIT 100;
