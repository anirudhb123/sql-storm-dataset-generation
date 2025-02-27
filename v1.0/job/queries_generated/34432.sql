WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        STRING_AGG(a.actor_name, ', ') AS cast,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles a ON mh.movie_id = a.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    mi.title,
    mi.production_year,
    mi.cast,
    mi.keyword_count,
    CASE 
        WHEN mi.keyword_count > 5 THEN 'Popular'
        WHEN mi.keyword_count BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Rare'
    END AS keyword_popularity,
    COALESCE(mh.depth, -1) AS hierarchy_depth
FROM 
    MovieInfo mi
LEFT JOIN 
    MovieHierarchy mh ON mi.title = mh.title AND mi.production_year = mh.production_year
WHERE 
    mi.production_year >= 2005
ORDER BY 
    mi.production_year DESC,
    mi.keyword_popularity DESC,
    mi.title;
