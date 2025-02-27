
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level,
        CONCAT(mh.hierarchy_path, ' -> ', at.title) AS hierarchy_path
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
title_keyword_count AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
final_output AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ck.actor_count, 0) AS actor_count,
        COALESCE(tk.keyword_count, 0) AS keyword_count,
        mh.level,
        mh.hierarchy_path,
        (CASE 
            WHEN ck.actor_count IS NULL THEN 'Unknown Actor Count' 
            ELSE CAST(ck.actor_count AS TEXT) 
        END) AS display_actor_count,
        (CASE 
            WHEN tk.keyword_count IS NULL THEN 'No Keywords' 
            ELSE CAST(tk.keyword_count AS TEXT) 
        END) AS display_keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles ck ON mh.movie_id = ck.movie_id
    LEFT JOIN 
        title_keyword_count tk ON mh.movie_id = tk.movie_id
    WHERE 
        mh.production_year >= 2000
)

SELECT 
    movie_id,
    title,
    production_year,
    actor_count,
    keyword_count,
    level,
    hierarchy_path,
    display_actor_count,
    display_keyword_count
FROM 
    final_output
ORDER BY 
    production_year DESC, 
    level, 
    title;
