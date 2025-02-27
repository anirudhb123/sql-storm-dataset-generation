WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 represents a movie in this schema

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_title,
        COUNT(cc.id) AS total_cast,
        AVG(COALESCE((SELECT COUNT(*) 
                      FROM movie_keyword mk 
                      WHERE mk.movie_id = mh.movie_id), 0)) AS avg_keywords,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mh.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        mh.movie_title
)
SELECT 
    ms.movie_title, 
    ms.total_cast, 
    ms.avg_keywords, 
    COALESCE(NULLIF(STRING_AGG(DISTINCT cn.name, ', '), ''), 'No Cast') AS cast_summary,
    CASE 
        WHEN ms.total_cast >= 10 THEN 'Large Cast'
        WHEN ms.total_cast BETWEEN 5 AND 9 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    MovieStats ms
LEFT JOIN 
    char_name cn ON cn.imdb_index = ms.movie_title
WHERE 
    ms.avg_keywords > 2 AND
    ms.total_cast IS NOT NULL
ORDER BY 
    ms.total_cast DESC, ms.movie_title
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
This query creates a recursive Common Table Expression (CTE) to gather a hierarchical list of movies based on their linked movies. It then calculates statistics for the total cast and average number of keywords associated with each movie, compiling a summary of cast names. Finally, it filters the results based on specific criteria and categorizes cast sizes for final output.
