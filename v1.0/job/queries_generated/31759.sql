WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    INNER JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'episode')
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(p.info, 'N/A') AS actor_info,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT co.name, ', ') AS production_companies,
    AVG(mk.keyword_count) AS avg_keywords,
    SUM(CASE WHEN at.production_year IS NULL THEN 0 ELSE 1 END) AS valid_movies,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS ranking
FROM 
    cast_info c
INNER JOIN 
    aka_name ak ON c.person_id = ak.person_id
INNER JOIN 
    aka_title at ON c.movie_id = at.movie_id
LEFT JOIN 
    movie_companies mc ON at.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    (SELECT movie_id, COUNT(keyword_id) AS keyword_count 
     FROM movie_keyword 
     GROUP BY movie_id) mk ON mk.movie_id = at.id
LEFT JOIN 
    person_info p ON p.person_id = ak.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
WHERE 
    ak.name IS NOT NULL AND
    at.production_year >= 2000
GROUP BY 
    ak.name, at.title, p.info
HAVING 
    COUNT(DISTINCT c.movie_id) > 2
ORDER BY 
    num_companies DESC, avg_keywords DESC;

This SQL query fetches detailed information regarding actors and the movies they have been involved in, focusing on production companies, the number of associated movies, keywords, and additional bio information. It utilizes recursive common table expressions (CTEs) to allow for nested episode structures, performs various joins and aggregations, and includes complex predicates and calculations, along with NULL handling via `COALESCE`. The final output is ordered by the number of production companies and average keyword counts while ensuring the actors have contributed to more than two films since 2000.
