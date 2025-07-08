
WITH RecursiveMovieList AS (
    SELECT title.id AS movie_id, title.title AS movie_title, title.production_year
    FROM title
    WHERE title.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT title.id AS movie_id, title.title, title.production_year
    FROM title
    JOIN movie_link ON title.id = movie_link.linked_movie_id
    WHERE movie_link.link_type_id = (SELECT id FROM link_type WHERE link = 'remake')
    AND title.production_year IS NOT NULL
    AND title.production_year > 2000
),
RelevantKeywords AS (
    SELECT movie_keyword.movie_id, LISTAGG(keyword.keyword, ', ') AS keywords
    FROM movie_keyword
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY movie_keyword.movie_id
),
PersonRoles AS (
    SELECT ca.movie_id, ak.name AS actor_name, 
           COALESCE(rt.role, 'Unknown Role') AS role, 
           ROW_NUMBER() OVER(PARTITION BY ca.movie_id ORDER BY ak.name) AS actor_order
    FROM cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
    LEFT JOIN role_type rt ON ca.role_id = rt.id
),
MoviesWithActorCount AS (
    SELECT rml.movie_id, rml.movie_title, rml.production_year,
           COUNT(DISTINCT pr.actor_name) AS actor_count
    FROM RecursiveMovieList rml
    LEFT JOIN PersonRoles pr ON rml.movie_id = pr.movie_id
    GROUP BY rml.movie_id, rml.movie_title, rml.production_year
)

SELECT m.movie_title, 
       m.production_year, 
       COALESCE(r.keywords, 'No keywords') AS keywords, 
       m.actor_count,
       m.actor_count - COUNT(pr.actor_name) OVER(PARTITION BY m.movie_id) AS missing_actors,
       CASE 
           WHEN m.actor_count = 0 THEN 'No cast available.'
           WHEN m.actor_count IS NULL THEN 'Actor count unknown.'
           ELSE 'Total cast: ' || m.actor_count
       END AS cast_info
FROM MoviesWithActorCount m
LEFT JOIN RelevantKeywords r ON m.movie_id = r.movie_id
LEFT JOIN PersonRoles pr ON m.movie_id = pr.movie_id
WHERE m.production_year BETWEEN 2001 AND 2023
AND NULLIF(m.actor_count, 0) IS NOT NULL
ORDER BY m.movie_title, m.production_year DESC
LIMIT 100;
