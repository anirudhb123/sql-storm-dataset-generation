WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Root movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, actor_stats AS (
    SELECT 
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS credited_roles,
        AVG(COALESCE(CHAR_LENGTH(a.name), 0)) AS avg_name_length,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_hierarchy mh ON ci.movie_id = mh.movie_id 
    GROUP BY 
        ak.person_id
)
SELECT 
    a.person_id,
    a.actor_names,
    a.total_movies,
    a.credited_roles,
    mh.title AS movie_title,
    mh.production_year,
    mh.depth,
    CASE 
        WHEN a.credited_roles = 0 THEN 'Uncredited'
        WHEN a.credited_roles <= 5 THEN 'Minor'
        ELSE 'Major'
    END AS actor_role_category
FROM 
    actor_stats a
LEFT JOIN 
    movie_hierarchy mh ON a.total_movies = mh.depth
WHERE 
    a.avg_name_length > 5 -- Only considering actors with longer names
ORDER BY 
    a.total_movies DESC, a.actor_names;

-- The query above aggregates actors' performance throughout movie links post-2000 and categorizes them based on the number of credited roles.
