WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000
      AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT ml.linked_movie_id, 
           lt.title, 
           lt.production_year, 
           mh.depth + 1
    FROM movie_link ml
    JOIN aka_title lt ON ml.linked_movie_id = lt.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.depth < 3
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    kr.keyword AS Keyword,
    COUNT(DISTINCT c.person_id) AS Cast_Count,
    AVG(p.info_type_id) AS Avg_Info_Type_ID,
    STRING_AGG(DISTINCT cn.name, ', ') AS Company_Names,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS Non_Null_Note_Count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS Row_Num
FROM MovieHierarchy mh
LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword kr ON mk.keyword_id = kr.id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN person_info p ON c.person_id = p.person_id
WHERE mh.depth <= 2
  AND (mh.production_year IS NOT NULL OR mh.production_year > 2010)
GROUP BY mh.movie_id, mh.title, mh.production_year, kr.keyword
HAVING COUNT(DISTINCT c.person_id) > 5
   AND AVG(COALESCE(p.info, 0)) > 1
ORDER BY mh.production_year DESC, Movie_Title ASC;
