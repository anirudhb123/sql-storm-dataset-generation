WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Filter for movies produced after 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        ak.title, 
        ak.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ak.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),

ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_within_level
    FROM 
        movie_hierarchy mh
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS person_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),

movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(CAST(cr.person_count AS integer), 0) AS role_count,
        COALESCE(k.keyword, 'No Keywords') AS keywords,
        CASE 
            WHEN mt.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(mt.production_year AS text)
        END AS production_year
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_roles cr ON mt.id = cr.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    md.title,
    md.production_year,
    md.role_count,
    md.keywords,
    rm.rank_within_level
FROM 
    movie_details md
LEFT JOIN 
    ranked_movies rm ON md.movie_id = rm.movie_id
WHERE 
    md.role_count > 0 
    AND rm.rank_within_level <= 5 -- Show only top 5 ranked movies per level
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
This complex SQL query includes multiple constructs such as Common Table Expressions (CTE), recursive queries, window functions, and outer joins. It retrieves movie details, their production years, role counts, and associated keywords while allowing for robust filtering and ordering based on specified criteria.
