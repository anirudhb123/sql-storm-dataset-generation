
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3 
),

qualified_cast AS (
    SELECT 
        ci.person_id,
        COUNT(*) AS movie_count,
        LISTAGG(DISTINCT at.title, ', ') WITHIN GROUP (ORDER BY at.title) AS titles_this_year
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON at.id = ci.movie_id
    WHERE 
        at.production_year >= 2000
        AND at.production_year = EXTRACT(YEAR FROM DATE '2024-10-01')
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(*) > 5
),

ranked_cast AS (
    SELECT 
        qc.person_id,
        qc.movie_count,
        qc.titles_this_year,
        ROW_NUMBER() OVER (ORDER BY qc.movie_count DESC) AS rank
    FROM 
        qualified_cast qc
),

outer_joined_data AS (
    SELECT 
        r.person_id,
        r.movie_count,
        r.titles_this_year,
        COALESCE(n.name, 'Unknown') AS actor_name,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        mh.level
    FROM 
        ranked_cast r
    LEFT JOIN 
        aka_name n ON n.person_id = r.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = r.person_id)
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_hierarchy mh ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = r.person_id)
),

final_output AS (
    SELECT 
        DISTINCT o.actor_name,
        o.movie_count,
        o.titles_this_year,
        o.keyword,
        o.level
    FROM 
        outer_joined_data o
    WHERE 
        o.level IS NOT NULL 
        OR EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = o.person_id))
)

SELECT 
    f.actor_name,
    f.movie_count,
    f.titles_this_year,
    f.keyword,
    f.level
FROM 
    final_output f
WHERE 
    (f.level > 1 AND f.keyword != 'No Keywords')
    OR (f.level <= 1 AND f.movie_count >= 10)
ORDER BY 
    f.movie_count DESC,
    f.actor_name
LIMIT 100;
