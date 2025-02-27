WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS title_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(STRING_AGG(DISTINCT ca.name, ', '), '') AS cast_names,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), '') AS company_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.movie_id
    LEFT JOIN 
        aka_name ca ON ca.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        mt.production_year >= 2000  
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),

keyword_summary AS (
    SELECT 
        mt.id AS title_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mt.id
)

SELECT 
    mh.title_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    mh.cast_names,
    mh.company_names,
    ks.keywords
FROM 
    movie_hierarchy mh
JOIN 
    keyword_summary ks ON mh.title_id = ks.title_id
ORDER BY 
    mh.production_year DESC, mh.title;