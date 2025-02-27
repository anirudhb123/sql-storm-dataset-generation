WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    INNER JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.id AS cast_info_id,
        a.name AS actor_name,
        mt.title AS movie_title,
        ci.nr_order,
        ROW_NUMBER() OVER(PARTITION BY mt.id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        aka_title mt ON ci.movie_id = mt.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.level,
    mh.title AS movie_title,
    cd.actor_name,
    cd.role_order,
    mk.keywords,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN 'Has Keywords'
        ELSE 'No Keywords'
    END AS keyword_status,
    COUNT(DISTINCT ci.person_id) OVER(PARTITION BY mh.movie_id) AS total_cast
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.level, mh.title, cd.role_order;

This query utilizes multiple complex constructs:

1. **Recursive CTE (`movie_hierarchy`)**: This retrieves a hierarchy of movies including individual episodes if present.
2. **Common Table Expression (CTE) for cast details (`cast_details`)**: It fetches cast information along with their respective ordering in the cast list using `ROW_NUMBER()`.
3. **Keyword aggregation (`movie_keywords`)**: A separate CTE aggregates keywords associated with each movie using `STRING_AGG()`.
4. **Outer joins**: `LEFT JOIN` is used to ensure that all movies are returned, even if they don’t have associated cast or keywords.
5. **Conditional logic**: A `CASE` statement determines the presence of keywords and labels them accordingly.
6. **Window functions**: `COUNT(DISTINCT ci.person_id) OVER(PARTITION BY mh.movie_id)` counts the total distinct cast members for each movie while maintaining the main query's row structure. 

This combination provides a comprehensive view of movie relationships, cast roles, and associated keywords.
