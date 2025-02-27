WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- let's assume "1" is for movies
   
    UNION ALL
   
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT rt.role ORDER BY rt.role) AS roles,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ni.info,
        COALESCE(NULLIF(ni.note, ''), 'No Note Available') AS note
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info ni ON mt.id = ni.movie_id
    WHERE 
        ni.info IS NOT NULL 
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.depth,
        ci.num_actors,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY ci.num_actors DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastRoles ci ON mh.movie_id = ci.movie_id
)
SELECT 
    rm.title,
    rm.depth,
    rm.num_actors,
    mi.info,
    mi.note
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 10 -- Top 10 movies per depth
ORDER BY 
    rm.depth, rm.rank;
