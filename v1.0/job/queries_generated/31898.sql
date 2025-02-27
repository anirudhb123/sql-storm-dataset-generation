WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

ranked_actors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name
),

movie_info_summary AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        COALESCE(ki.keyword, 'No Keywords') AS keyword,
        COALESCE(mi.info, 'No Info') AS additional_info,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, ki.keyword, mi.info
),

final_summary AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mis.keyword,
        mis.additional_info,
        mis.cast_count,
        ra.actor_name
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_info_summary mis ON mh.movie_id = mis.movie_id
    LEFT JOIN 
        ranked_actors ra ON ra.movie_count > 3
    WHERE 
        mh.level <= 2
    ORDER BY 
        mh.level, mis.cast_count DESC
)

SELECT 
    fs.movie_id,
    fs.movie_title,
    fs.keyword,
    fs.additional_info,
    fs.cast_count,
    fs.actor_name
FROM 
    final_summary fs
WHERE 
    fs.cast_count > 0
ORDER BY 
    fs.movie_id;
