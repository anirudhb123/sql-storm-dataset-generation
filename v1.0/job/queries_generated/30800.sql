WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2021
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.linked_movie_id,
        t.title,
        t.production_year,
        h.depth + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy h ON m.movie_id = h.movie_id
)

SELECT 
    h.title AS Movie_Title,
    h.production_year AS Production_Year,
    h.depth AS Link_Depth,
    COUNT(DISTINCT ci.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT ak.name, ', ') AS Actors,
    AVG(CASE 
        WHEN mid.note IS NOT NULL THEN 1 
        ELSE NULL 
    END) AS Info_Status,
    COALESCE(MAX(kw.keyword), 'N/A') AS Popular_Keyword
FROM 
    MovieHierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mid ON h.movie_id = mid.movie_id 
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id 
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id 
WHERE 
    h.depth <= 3 -- Limiting depth to avoid excessive growth
GROUP BY 
    h.movie_id, h.title, h.production_year, h.depth
ORDER BY 
    h.production_year DESC, Link_Depth, Cast_Count DESC;
