WITH filtered_titles AS (
    SELECT id, title, production_year, kind_id
    FROM aka_title
    WHERE production_year BETWEEN 2000 AND 2020
),
actor_movie_roles AS (
    SELECT ci.movie_id, count(DISTINCT ci.person_id) AS actor_count, 
           STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
movies_with_keywords AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 
           ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM filtered_titles m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, m.title, m.production_year
),
movie_info_details AS (
    SELECT mi.movie_id, STRING_AGG(DISTINCT it.info, ', ') AS info_details
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT m.title, m.production_year, 
       COALESCE(am.actor_count, 0) AS number_of_actors, 
       COALESCE(am.actor_names, 'No actors') AS actor_list, 
       COALESCE(mk.keywords, ARRAY[]::text[]) AS movie_keywords, 
       COALESCE(mid.info_details, 'No additional info') AS additional_info
FROM movies_with_keywords m
LEFT JOIN actor_movie_roles am ON m.movie_id = am.movie_id
LEFT JOIN movie_info_details mid ON m.movie_id = mid.movie_id
ORDER BY m.production_year DESC, m.title;
