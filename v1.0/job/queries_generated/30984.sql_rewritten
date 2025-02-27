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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3 
),
CastDetails AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT cct.kind) AS cast_type_count,
        STRING_AGG(DISTINCT cct.kind, ', ') AS cast_types
    FROM
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type cct ON ci.person_role_id = cct.id
    GROUP BY
        ci.movie_id, ak.name
),
GenreCounts AS (
    SELECT
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS genre_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.cast_type_count,
    cd.cast_types,
    gc.genre_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_id) AS row_num,
    CASE 
        WHEN gc.genre_count IS NULL THEN 'No Genres'
        WHEN gc.genre_count > 0 THEN 'Has Genres'
        ELSE 'Unknown'
    END AS genre_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    GenreCounts gc ON mh.movie_id = gc.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.title;