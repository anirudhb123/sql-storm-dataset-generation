WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON m.episode_of_id = mh.movie_id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(k.keyword, 'No Keywords') AS Movie_Keyword,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NOT NULL) AS Cast_Count,
    AVG(CASE 
        WHEN ci.nr_order IS NOT NULL THEN ci.nr_order
        ELSE NULL 
    END) AS Average_Order,
    STRING_AGG(DISTINCT ak.name, ', ') AS Alternate_Names,
    COUNT(DISTINCT mc.company_id) AS Company_Count,
    SUM(CASE 
        WHEN mc.note IS NOT NULL THEN 1 
        ELSE 0 
    END) AS Noted_Companies,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS Rank_Per_Year
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = m.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    (m.production_year IS NOT NULL AND m.production_year >= 2000) 
    OR (m.production_year IS NULL AND m.title IS NOT NULL)
GROUP BY 
    m.movie_id, m.title, m.production_year, k.keyword
ORDER BY 
    Production_Year DESC, Movie_Title ASC;
