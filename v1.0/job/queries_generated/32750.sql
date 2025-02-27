WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Consider movies produced from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    COUNT(DISTINCT c.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT ak.name, ', ') AS Actors,
    MAX(mci.note) AS Company_Note,
    MIN(CASE WHEN ki.keyword IS NOT NULL THEN ki.keyword ELSE 'No Keywords' END) AS Movie_Keyword,
    AVG(CASE 
            WHEN mi.info IS NOT NULL THEN LENGTH(mi.info)
            ELSE NULL END) AS Avg_Info_Length,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS Cast_Rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id  -- Person who played a role in the movie
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name ci ON mc.company_id = ci.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%trivia%')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 0  -- Filter to include only movies with cast
ORDER BY 
    mh.production_year DESC, Cast_Count DESC;
