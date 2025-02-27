WITH RECURSIVE MovieHierarchy AS (
    SELECT
        title.id AS movie_id,
        title.title,
        title.production_year,
        title.kind_id,
        title.imdb_index,
        1 AS level
    FROM title
    WHERE title.production_year >= 2000

    UNION ALL

    SELECT
        link.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        mh.level + 1
    FROM movie_link AS link
    JOIN title AS t ON link.linked_movie_id = t.id
    JOIN MovieHierarchy AS mh ON link.movie_id = mh.movie_id
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    comp.name AS Company_Name,
    GROUP_CONCAT(DISTINCT key.keyword ORDER BY key.keyword) AS Keywords,
    COUNT(DISTINCT cast.person_id) AS Cast_Count,
    AVG(CASE WHEN info.info IS NOT NULL THEN LENGTH(info.info) ELSE NULL END) AS Avg_Info_Length,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT cast.person_id) DESC) AS Rank_By_Cast_Count
FROM MovieHierarchy AS mh
LEFT JOIN movie_companies AS mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_name AS comp ON mc.company_id = comp.id
LEFT JOIN movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword AS key ON mk.keyword_id = key.id
LEFT JOIN complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info AS cast ON cc.subject_id = cast.person_id
LEFT JOIN movie_info AS info ON mh.movie_id = info.movie_id AND info.info_type_id = (
    SELECT id FROM info_type WHERE info = 'Summary'
)
WHERE mh.level <= 3
  AND (comp.country_code IS NOT NULL OR comp.country_code IS NULL)
GROUP BY mh.movie_id, mh.title, mh.production_year, comp.name
HAVING COUNT(DISTINCT cast.person_id) > 5
ORDER BY Rank_By_Cast_Count, mh.production_year DESC;
