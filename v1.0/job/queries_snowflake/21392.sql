
WITH RECURSIVE TitleHierarchy AS (
    SELECT t.id AS title_id,
           t.title,
           t.production_year,
           t.kind_id,
           t.episode_of_id,
           1 AS level
    FROM title t
    WHERE t.production_year > 2000

    UNION ALL

    SELECT t.id AS title_id,
           t.title,
           t.production_year,
           t.kind_id,
           t.episode_of_id,
           th.level + 1
    FROM title t
    JOIN TitleHierarchy th ON t.episode_of_id = th.title_id
)

SELECT 
    ak.name AS actor_name,
    tit.title AS movie_title,
    (CASE 
        WHEN tit.production_year > 2010 THEN 'Modern'
        WHEN tit.production_year BETWEEN 2000 AND 2010 THEN 'Contemporary'
        ELSE 'Classic'
     END) AS era,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS more_info,
    ROW_NUMBER() OVER(PARTITION BY ak.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
FROM aka_name ak
JOIN cast_info c ON ak.person_id = c.person_id
JOIN aka_title tit ON c.movie_id = tit.movie_id
LEFT JOIN movie_info mi ON tit.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
LEFT JOIN TitleHierarchy th ON tit.id = th.title_id
WHERE ak.name IS NOT NULL
AND tit.production_year IS NOT NULL
AND EXTRACT(YEAR FROM CURRENT_DATE()) - tit.production_year < 20
GROUP BY ak.name, tit.title, tit.production_year
HAVING COUNT(DISTINCT c.movie_id) > 3
ORDER BY rank, era DESC
LIMIT 10;
