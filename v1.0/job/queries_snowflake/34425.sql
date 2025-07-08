
WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL

    
    SELECT 
        ae.id AS movie_id,
        ae.title,
        mh.level + 1
    FROM 
        aka_title ae
    JOIN 
        movie_hierarchy mh ON ae.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
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
    mh.movie_id,
    mh.title,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
ORDER BY 
    mh.level DESC, mh.title;
