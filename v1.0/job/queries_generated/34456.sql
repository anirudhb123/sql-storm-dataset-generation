WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mt.production_year >= 2000
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        count(ci.movie_id) AS movies_count,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY count(ci.movie_id) DESC) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ci.note IS NOT NULL 
    GROUP BY 
        ak.id, ak.name
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ad.actor_name,
        ad.movies_count,
        mh.level,
        mh.path
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    JOIN 
        ActorDetails ad ON ci.person_id = ad.actor_id
    WHERE 
        ad.rank <= 3
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.movies_count,
    md.level,
    md.path
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.movies_count DESC;
