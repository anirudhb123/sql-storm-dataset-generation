WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming kind_id = 1 corresponds to 'movie'

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5  -- Limit to a maximum hierarchy level
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),

MovieKeyword AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT cd.actor_name) AS total_actors,
    COALESCE(mk.keywords, 'No Keywords') AS associated_keywords,
    ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT cd.actor_name) > 2
ORDER BY 
    mh.production_year DESC, total_actors DESC;

This SQL query involves several advanced constructs:
- A recursive CTE `MovieHierarchy` to explore a hierarchy of linked movies.
- Another CTE `CastDetails` to get details about the cast of each movie through aggregation.
- A third CTE `MovieKeyword` that aggregates keywords for movies.
- It pulls together the movies from the hierarchy, counts distinct actors, and joins with keywords, applying complex predicates and aggregations.
- It includes a ranking mechanism with a window function based on production year and actor count, filtering out movies with fewer than three actors.
