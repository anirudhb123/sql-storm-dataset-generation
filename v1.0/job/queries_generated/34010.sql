WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
), RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
), CastAndCrew AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        COALESCE(cct.kind, 'Unknown Role') AS role_type
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        comp_cast_type cct ON ci.role_id = cct.id
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT cac.actor_name) AS actor_count,
        STRING_AGG(DISTINCT cac.role_type, ', ') AS roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastAndCrew cac ON rm.movie_id = cac.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.roles,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    CASE 
        WHEN md.actor_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC,
    md.actor_count DESC;
