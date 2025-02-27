WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE
        mh.depth < 3  
),
ActorRoles AS (
    SELECT 
        ca.person_id,
        ka.name AS actor_name,
        COALESCE(STRING_AGG(rt.role, ', '), 'Unknown') AS roles
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    LEFT JOIN 
        role_type rt ON ca.role_id = rt.id
    GROUP BY 
        ca.person_id, ka.name 
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ac.person_id) AS actor_count,
        AVG(mk.keywords_count) AS avg_keywords_per_movie,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ac.person_id) DESC) AS rank_by_actors
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        (SELECT movie_id, COUNT(*) AS keywords_count 
         FROM movie_keyword 
         GROUP BY movie_id) mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        ActorRoles ac ON ac.person_id = ca.person_id
    WHERE 
        mh.production_year IS NOT NULL
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
FilteredMovies AS (
    SELECT *
    FROM MovieDetails
    WHERE actor_count > 5 AND production_year BETWEEN 2000 AND 2023
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.avg_keywords_per_movie,
    ar.actor_name,
    ar.roles
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorRoles ar ON fm.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ar.person_id LIMIT 1)
WHERE 
    fm.rank_by_actors <= 5
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;