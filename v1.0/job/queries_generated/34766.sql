WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ll.linked_movie_id,
        mt.title,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', mt.title)
    FROM 
        movie_link ll
    JOIN 
        aka_title mt ON ll.linked_movie_id = mt.movie_id
    JOIN 
        MovieHierarchy mh ON ll.movie_id = mh.movie_id
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.production_year,
        SUM(mi.info IS NOT NULL) AS info_count,
        STRING_AGG(DISTINCT mi.info || ': ' || mi.note, '; ') AS info_details
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    GROUP BY 
        mt.id, mt.production_year
),
RankedActors AS (
    SELECT 
        ca.movie_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_rank,
        COUNT(ca.person_id) OVER (PARTITION BY ca.movie_id) AS total_actors
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
),
FilteredActors AS (
    SELECT 
        ra.movie_id,
        ra.name,
        ra.actor_rank,
        ra.total_actors,
        CASE 
            WHEN ra.actor_rank <= 3 THEN 'Top Actor'
            ELSE 'Supporting Actor'
        END AS actor_type
    FROM 
        RankedActors ra
    WHERE 
        ra.total_actors > 10
)
SELECT 
    mh.level,
    mh.path,
    mi.production_year,
    mi.info_count,
    fa.actor_type,
    fa.name
FROM 
    MovieHierarchy mh
JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    FilteredActors fa ON mh.movie_id = fa.movie_id
WHERE 
    mi.production_year IS NOT NULL
ORDER BY 
    mi.production_year DESC, mh.level, fa.actor_rank;
