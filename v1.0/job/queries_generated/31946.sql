WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, 
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           NULL AS parent_actor
    FROM cast_info ci
    GROUP BY ci.person_id
    HAVING COUNT(DISTINCT ci.movie_id) > 5

    UNION ALL

    SELECT ci.person_id,
           COUNT(DISTINCT ci.movie_id) + ah.movie_count AS movie_count,
           ah.person_id AS parent_actor
    FROM cast_info ci
    JOIN actor_hierarchy ah ON ci.movie_id IN (
        SELECT movie_id FROM cast_info WHERE person_id = ah.person_id
    )
    GROUP BY ci.person_id, ah.movie_count
)

SELECT a.name AS actor_name,
       COUNT(DISTINCT c.movie_id) AS total_movies,
       AVG(EXTRACT(YEAR FROM (SELECT min(production_year) 
                              FROM aka_title at 
                              WHERE at.id = c.movie_id))) AS avg_year_first_movie,
       STRING_AGG(DISTINCT at.title, ', ') AS movie_titles,
       COALESCE(NULLIF(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 END), 0), 0) AS notes_count,
       ARRAY_AGG(DISTINCT cn.name) AS company_names,
       ah.parent_actor
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title at ON ci.movie_id = at.movie_id
JOIN movie_companies mc ON mc.movie_id = ci.movie_id
JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN actor_hierarchy ah ON a.person_id = ah.person_id
WHERE at.production_year > 2000
GROUP BY a.name, ah.parent_actor
HAVING COUNT(DISTINCT ci.movie_id) > 10
ORDER BY total_movies DESC;

WITH movie_keyword_cte AS (
    SELECT mk.movie_id, 
           COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

popular_movies AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           mkc.keyword_count
    FROM title m
    JOIN movie_keyword_cte mkc ON m.id = mkc.movie_id
    WHERE m.production_year BETWEEN 2010 AND 2023
    ORDER BY mkc.keyword_count DESC
    LIMIT 10
)

SELECT pm.title, 
       pm.production_year,
       COUNT(DISTINCT c.person_id) AS total_actors,
       AVG(CASE 
           WHEN mf.info LIKE '%Academy Award%' THEN 1 
           ELSE 0 
           END) AS avg_academy_awards,
       SUM(CASE 
           WHEN ci.note IS NULL THEN 1 
           ELSE 0 
           END) AS missing_notations
FROM popular_movies pm
JOIN complete_cast cc ON pm.movie_id = cc.movie_id
JOIN cast_info c ON cc.subject_id = c.id
LEFT JOIN movie_info mf ON pm.movie_id = mf.movie_id 
WHERE mf.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
GROUP BY pm.title, pm.production_year
ORDER BY total_actors DESC;

This SQL query accomplishes several objectives:

1. It uses a recursive CTE to create a hierarchy of actors based on their movie counts.
2. It aggregates information about movies related to actors, pulling in details about movie titles, production years, and counts related to notes and companies.
3. It filters based on considerable conditions and aggregates results.
4. It includes nested queries, outer joins, and complex aggregations to derive additional statistics regarding movies in the second part of the query.
5. It demonstrates advanced SQL constructs while addressing the schema provided comprehensively.
