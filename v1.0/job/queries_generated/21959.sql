WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        NULL::integer AS parent_movie_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        ml.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
, title_keyword AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)
, ranked_cast AS (
    SELECT 
        ci.movie_id,
        an.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
)
, detailed_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.parent_movie_id,
        mh.level,
        tk.keywords,
        CAST(COALESCE(COUNT(rc.actor_rank), 0) AS integer) AS actor_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        title_keyword tk ON mh.movie_id = tk.movie_id
    LEFT JOIN 
        ranked_cast rc ON mh.movie_id = rc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.parent_movie_id, mh.level, tk.keywords
)
SELECT 
    dm.movie_id,
    dm.title,
    dm.keywords,
    dm.actor_count,
    (CASE 
        WHEN dm.level = 0 THEN 'Top Level Movie'
        WHEN dm.level = 1 THEN 'Linked Movie'
        ELSE 'Subsequent Level'
    END) AS movie_relationship,
    COALESCE(dm.keywords, 'No Keywords') AS keywords_summary
FROM 
    detailed_movies dm
WHERE 
    dm.actor_count > 0
ORDER BY 
    dm.actor_count DESC, 
    dm.title;
