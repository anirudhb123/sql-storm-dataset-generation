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
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 

CombinedCast AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        ak.id AS actor_id, 
        COUNT(ci.nr_order) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
FilteredMovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS infos
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    coalesce(fc.actor_count, 0) AS total_actors,
    fi.infos,
    CASE 
        WHEN m.production_year BETWEEN 1990 AND 2023 THEN 'Modern Era'
        ELSE 'Classic Era'
    END AS era,
    CASE 
        WHEN fi.infos IS NULL THEN 'No Info Available'
        ELSE 'Information Exists'
    END AS info_status,
    COUNT(DISTINCT CASE 
        WHEN fc.actor_count > 5 THEN fc.actor_id 
        END) OVER() AS popular_actor_count
FROM 
    MovieHierarchy m
LEFT JOIN 
    CombinedCast fc ON m.movie_id = fc.movie_id
LEFT JOIN 
    FilteredMovieInfo fi ON m.movie_id = fi.movie_id
WHERE 
    m.depth <= 3 
    AND (m.production_year IS NOT NULL OR m.title IS NOT NULL)
ORDER BY 
    m.production_year DESC, 
    total_actors DESC
LIMIT 50;
