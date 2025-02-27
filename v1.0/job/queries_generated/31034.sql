WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.id = ci.movie_id
    GROUP BY 
        mh.movie_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
movie_keywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
movie_info_combined AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE(i.info, 'No Info Available') AS additional_info
    FROM 
        top_movies m
    LEFT JOIN 
        movie_keywords k ON m.movie_id = k.movie_id
    LEFT JOIN 
        movie_info i ON m.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
)
SELECT 
    m.title,
    m.production_year,
    m.keywords,
    ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS ranking,
    CASE 
        WHEN m.production_year >= 2020 THEN 'Recent'
        ELSE 'Classic'
    END AS era,
    COUNT(DISTINCT ci.person_id) AS unique_actors,
    (SELECT COUNT(*)
     FROM movie_keyword
     WHERE movie_id = m.movie_id) AS keyword_count
FROM 
    movie_info_combined m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.movie_id
WHERE
    (m.keywords IS NOT NULL AND m.keywords != 'No Keywords')
    OR (m.additional_info IS NOT NULL AND m.additional_info != 'No Info Available')
GROUP BY 
    m.title, m.production_year, m.keywords
ORDER BY 
    ranking;
