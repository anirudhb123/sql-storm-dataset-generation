WITH recursive movie_expansion AS (
    -- Recursive CTE to expand movies with related entries
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        coalesce(mk.keyword, 'No Keyword') AS keyword,
        mi.info AS additional_info,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        coalesce(mk.keyword, 'No Keyword') AS keyword,
        mi.info AS additional_info,
        level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.movie_id
    INNER JOIN 
        movie_expansion me ON ml.linked_movie_id = me.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        level < 3  -- constrain recursion depth for performance
),

-- CTE to rank movies by their production year and keyword presence
ranked_movies AS (
    SELECT 
        me.movie_id,
        me.title,
        me.production_year,
        me.keyword,
        me.additional_info,
        ROW_NUMBER() OVER (PARTITION BY me.keyword ORDER BY me.production_year DESC) AS rank_desc,
        COUNT(*) OVER (PARTITION BY me.keyword) AS keyword_count
    FROM 
        movie_expansion me
)

-- Main query to find unique movies with their roles, excluding those with NULL in critical fields
SELECT 
    n.name AS actor_name,
    rm.title,
    rm.production_year,
    rm.keyword,
    rm.additional_info,
    CASE 
        WHEN rm.rank_desc = 1 THEN 'Top Ranked'
        ELSE 'Other'
    END AS ranking_category,
    COALESCE(ci.note, 'No Role') AS role_note
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id AND n.name IS NOT NULL
WHERE 
    rm.keyword_count > 1 
    AND rm.production_year > 2000
    AND (ci.role_id IS NOT NULL OR ci.note IS NOT NULL)
ORDER BY 
    rm.production_year DESC,
    rm.keyword;

-- The query incorporates recursive CTEs, window functions, outer joins, keyword uniqueness,
-- and intricate filtering logic to perform a detailed performance benchmark of interconnected movie data,
-- including handling NULLs and emphasizing (non-NULL) roles with a bizarre 'ranking_category'.
