WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

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
),
title_with_keywords AS (
    SELECT 
        at.title,
        array_agg(k.keyword) AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
),
cast_with_roles AS (
    SELECT 
        ac.id AS cast_id,
        ac.movie_id,
        ak.name AS actor_name,
        rp.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ac.movie_id ORDER BY ac.nr_order) AS role_order
    FROM 
        cast_info ac
    JOIN 
        aka_name ak ON ac.person_id = ak.person_id
    LEFT JOIN 
        role_type rp ON ac.role_id = rp.id
),
movies_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COALESCE(cw.actor_name, 'Unknown Actor') AS actor_name,
        cw.role_name,
        mh.depth,
        tk.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles cw ON mh.movie_id = cw.movie_id
    LEFT JOIN 
        title_with_keywords tk ON mh.title = tk.title
    WHERE 
        mh.production_year > 1990 AND (mh.kind_id IS NULL OR mh.kind_id BETWEEN 1 AND 10)
),
final_result AS (
    SELECT 
        *,
        CASE 
            WHEN keywords IS NULL THEN 'No Keywords'
            ELSE 'Keywords Present'
        END AS keyword_status,
        COUNT(actor_name) OVER (PARTITION BY movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS actor_rank
    FROM 
        movies_with_cast
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    role_name,
    depth,
    keyword_status,
    keywords,
    actor_count,
    actor_rank
FROM 
    final_result
WHERE 
    actor_rank <= 5 AND (depth < 3 OR actor_count > 2)
ORDER BY 
    production_year DESC, actor_count DESC;
