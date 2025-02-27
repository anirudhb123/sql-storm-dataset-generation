WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth 
    FROM 
        aka_title mt 
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mh.depth + 1 
    FROM 
        movie_link ml 
    JOIN aka_title mt ON ml.linked_movie_id = mt.id 
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
), 
cast_details AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER(PARTITION BY ci.person_id ORDER BY mt.production_year DESC) AS role_rank
    FROM 
        cast_info ci 
    JOIN aka_name a ON ci.person_id = a.person_id 
    JOIN aka_title mt ON ci.movie_id = mt.id 
    WHERE 
        mt.production_year > 2000
), 
company_overview AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc 
    JOIN company_name cn ON mc.company_id = cn.id 
    JOIN company_type ct ON mc.company_type_id = ct.id 
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk 
    JOIN keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.role_rank,
    co.company_name,
    co.company_type,
    mk.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id AND cd.role_rank = 1
LEFT JOIN 
    company_overview co ON mh.movie_id = co.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.depth <= 3 
ORDER BY 
    mh.production_year DESC, mh.title ASC
LIMIT 50;
