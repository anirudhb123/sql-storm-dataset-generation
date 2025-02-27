WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
  
    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
),

recent_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title)
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),

title_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(d.info, 'No Additional Info') AS additional_info
    FROM 
        title t
    LEFT JOIN 
        movie_info d ON t.id = d.movie_id AND d.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.num_cast_members,
    cs.cast_names,
    COALESCE(ti.additional_info, 'None') AS additional_info,
    rh.keyword,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.num_cast_members DESC) AS rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    recent_movies rh ON mh.movie_id = rh.movie_id
LEFT JOIN 
    title_info ti ON mh.movie_id = ti.movie_id
WHERE 
    cs.num_cast_members IS NOT NULL
ORDER BY 
    mh.production_year DESC,
    cs.num_cast_members DESC
LIMIT 100;

