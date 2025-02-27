WITH MovieDetails AS (
    SELECT m.id AS movie_id, 
           m.title AS movie_title, 
           m.production_year, 
           k.keyword AS movie_keyword,
           ARRAY_AGG(DISTINCT c.name) AS actors,
           COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON m.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    JOIN movie_companies mc ON m.id = mc.movie_id
    GROUP BY m.id, m.title, m.production_year, k.keyword
),

ActorRoles AS (
    SELECT c.person_id, 
           c.role_id,
           r.role AS role_name,
           COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    JOIN complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY c.person_id, c.role_id, r.role
)

SELECT md.movie_title, 
       md.production_year, 
       ARRAY_AGG(DISTINCT md.actors) AS all_actors,
       md.movie_keyword,
       ar.role_name,
       ar.movie_count,
       md.production_company_count
FROM MovieDetails md
JOIN ActorRoles ar ON ar.person_id IN (
    SELECT c.person_id 
    FROM cast_info c 
    JOIN complete_cast cc ON c.movie_id = cc.movie_id 
    WHERE cc.movie_id = md.movie_id
)
GROUP BY md.movie_title, 
         md.production_year, 
         md.movie_keyword, 
         ar.role_name
ORDER BY md.production_year DESC, 
         md.movie_title;

This query serves to benchmark string processing by aggregating several pieces of information regarding movies, including their titles, production years, associated keywords, actors, and the roles they played. The use of common table expressions (CTEs) allows for clear segmentation of logic, while the use of `ARRAY_AGG` showcases the capability of working with string sets as well as complex joins across multiple tables.
