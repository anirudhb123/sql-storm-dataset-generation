WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
), 

MostFrequentActors AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
    HAVING 
        COUNT(*) > 1
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(f.actor_name, 'No actor') AS leading_actor,
    COALESCE(f.role_count, 0) AS actor_roles,
    COALESCE(k.keywords_list, 'No keywords') AS keywords,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MostFrequentActors f ON mh.movie_id = f.movie_id
LEFT JOIN 
    MovieKeywords k ON mh.movie_id = k.movie_id
WHERE 
    mh.depth <= 2
ORDER BY 
    mh.production_year DESC, 
    mh.title, 
    mh.depth;
