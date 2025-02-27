WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit recursion to avoid infinite loops
),

cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS primary_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

keyword_stats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword_id::text, ', ') AS keyword_ids,
        COUNT(mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast_members,
    COALESCE(cs.primary_roles, 0) AS total_primary_roles,
    COALESCE(ks.total_keywords, 0) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword::text, ', ') AS keywords_used,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_stats ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cs.total_cast, cs.primary_roles, ks.total_keywords
ORDER BY 
    mh.production_year DESC, mh.title;

This query uses recursive CTEs to build up a hierarchy of movies linked together, gathers statistics on cast and keywords associated with those movies, and returns a comprehensive summary including total cast members, primary roles, keyword counts, and categorization by era based on the production year. It showcases multiple advanced SQL constructs, including outer joins, CTEs, aggregate functions, string manipulation, and conditional logic.
