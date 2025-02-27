WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
),
movie_cast_info AS (
    SELECT 
        mc.movie_id,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        complete_cast AS mc
    LEFT JOIN 
        cast_info AS c ON mc.movie_id = c.movie_id
    LEFT JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        mc.movie_id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ci.cast_count, 0) AS total_cast,
        COALESCE(ki.keywords, 'None') AS keywords
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        movie_cast_info AS ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        keyword_info AS ki ON mh.movie_id = ki.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.keywords,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank_within_year
FROM 
    movie_details AS md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year, md.total_cast DESC;
