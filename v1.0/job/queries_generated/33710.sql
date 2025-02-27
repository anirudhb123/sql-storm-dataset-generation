WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t 
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        mc.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        title mt ON mc.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    kt.keyword AS Keywords,
    COUNT(DISTINCT ci.person_id) AS Cast_Count,
    AVG(CASE 
        WHEN pi.info IS NULL THEN 0 
        ELSE LENGTH(pi.info) 
    END) AS Avg_Info_Length,
    MAX(CASE 
        WHEN ci.nr_order IS NULL THEN 0 
        ELSE ci.nr_order 
    END) AS Max_Order,
    STRING_AGG(DISTINCT ak.name, ', ') AS Aka_Names,
    CASE 
        WHEN COUNT(DISTINCT ci.role_id) > 2 THEN 'Diverse Cast' 
        ELSE 'Limited Cast' 
    END AS Cast_Variability
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id 
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id 
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id 
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id 
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id 
WHERE 
    mh.level < 3 
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, kt.keyword
ORDER BY 
    Production_Year DESC, Cast_Count DESC;
