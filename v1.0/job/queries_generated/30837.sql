WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.level + 1
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    SUM(CASE WHEN cc.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_lead_roles,
    MAX(COALESCE(ci.note, 'No note available')) AS role_note,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank
FROM aka_name ak
JOIN cast_info cc ON ak.person_id = cc.person_id
JOIN movie_info mi ON cc.movie_id = mi.movie_id
JOIN aka_title mt ON cc.movie_id = mt.id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN MovieHierarchy mh ON mt.id = mh.movie_id
WHERE mt.production_year IS NOT NULL
GROUP BY ak.name, mt.title, mt.production_year
HAVING COUNT(DISTINCT cc.person_id) > 1
ORDER BY mt.production_year DESC, total_cast DESC;

In this SQL query:
- A recursive CTE (`MovieHierarchy`) generates a hierarchy of movies and their episodes.
- The main SELECT statement aggregates data on actors, movies, roles, keywords, and production companies, applying various joins including LEFT JOINs to retain movies with possibly missing data.
- It calculates the total number of cast members and the total number of lead roles, along with using `STRING_AGG` to concatenate keywords and company names.
- The `HAVING` clause filters out movies with only one cast member.
- The `ROW_NUMBER` window function ranks the movies within their production year based on the number of cast members.
