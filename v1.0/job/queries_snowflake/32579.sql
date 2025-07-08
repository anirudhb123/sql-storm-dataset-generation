
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
  
    UNION ALL
  
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  
),
cast_ranks AS (
    SELECT 
        ci.movie_id,
        c.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    ck.name AS main_actor,
    ck.rank AS actor_rank,
    mk.keywords,
    COUNT(DISTINCT mc.company_id) AS num_companies
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_ranks ck ON mh.movie_id = ck.movie_id AND ck.rank = 1  
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, ck.name, ck.rank, mk.keywords
ORDER BY 
    mh.production_year DESC, mh.level, ck.name;
