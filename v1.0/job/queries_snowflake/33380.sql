
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
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
        mh.level < 3
),
top_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(tc.actor_name, 'Unknown') AS lead_actor,
        COALESCE(tc.role_count, 0) AS actor_roles,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        top_cast tc ON mh.movie_id = tc.movie_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, tc.actor_name, tc.role_count
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.lead_actor,
    md.actor_roles,
    md.company_count,
    ks.keywords
FROM 
    movie_details md
LEFT JOIN 
    keyword_summary ks ON md.movie_id = ks.movie_id
WHERE 
    (md.actor_roles > 2 OR (md.company_count > 5 AND md.production_year > 2010))
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 100 OFFSET 0;
