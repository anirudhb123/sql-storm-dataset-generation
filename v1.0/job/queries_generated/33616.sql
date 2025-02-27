WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS level
    FROM cast_info ci
    WHERE ci.role_id = (SELECT id FROM role_type WHERE role = 'Lead')
    
    UNION ALL
    
    SELECT ci.person_id, ci.movie_id, ah.level + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.role_id <> (SELECT id FROM role_type WHERE role = 'Lead') 
)
, MovieRatings AS (
    SELECT mt.movie_id, AVG(mv.rating) AS avg_rating
    FROM movie_info mv
    JOIN movie_info_idx mt ON mt.movie_id = mv.movie_id
    WHERE mv.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY mt.movie_id
)
, CompanyMovieCounts AS (
    SELECT mc.company_id, COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.company_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COALESCE(mr.avg_rating, -1) AS average_rating,
    cc.movie_count AS company_movie_count,
    ah.level AS actor_level,
    STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN ActorHierarchy ah ON ah.person_id = ci.person_id
JOIN aka_title mt ON mt.movie_id = ci.movie_id
LEFT JOIN MovieRatings mr ON mr.movie_id = ci.movie_id
JOIN movie_companies mc ON mc.movie_id = ci.movie_id
JOIN CompanyMovieCounts cc ON cc.company_id = mc.company_id
LEFT JOIN movie_keyword mk ON mk.movie_id = ci.movie_id
LEFT JOIN keyword ON keyword.id = mk.keyword_id
WHERE mt.production_year > 2000
AND (mr.avg_rating IS NULL OR mr.avg_rating > 7)
GROUP BY ak.name, mt.title, mr.avg_rating, cc.movie_count, ah.level
ORDER BY average_rating DESC, actor_name;  
