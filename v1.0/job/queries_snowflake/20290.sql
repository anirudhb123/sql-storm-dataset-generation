WITH recursive MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
), RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank
    FROM 
        MovieHierarchy mh
), ActorRoles AS (
    SELECT 
        ak.name,
        ci.movie_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL AND ak.name != ''
), MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.name AS actor_name,
        ar.role,
        COALESCE(ar.role_order, 10) AS role_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        (rm.production_year % 2 = 0 AND ar.role IS NOT NULL) OR 
        (rm.production_year % 2 = 1 AND ar.role IS NULL)
), SummarizedInfo AS (
    SELECT 
        mw.movie_id,
        COUNT(mw.actor_name) AS actor_count,
        MIN(mw.role_order) AS first_role_order,
        MAX(mw.role_order) AS last_role_order
    FROM 
        MoviesWithActors mw
    GROUP BY 
        mw.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    si.actor_count,
    CASE 
        WHEN si.actor_count > 5 THEN 'Popular'
        WHEN si.first_role_order = si.last_role_order THEN 'Consistency in Roles'
        ELSE 'Diverse Cast'
    END AS cast_description,
    CASE 
        WHEN mi.production_year < 2010 THEN 'Classic'
        WHEN mi.production_year < 2020 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age,
    COALESCE(si.actor_count, 0) AS null_actor_count_handling
FROM 
    RankedMovies mi
LEFT JOIN 
    SummarizedInfo si ON mi.movie_id = si.movie_id
WHERE 
    mi.title ILIKE '%the%'
ORDER BY 
    mi.production_year DESC, 
    si.actor_count ASC NULLS LAST;
