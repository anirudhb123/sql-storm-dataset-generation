WITH filtered_titles AS (
    SELECT t.id AS title_id, 
           t.title, 
           t.production_year, 
           kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
      AND kt.kind IN ('movie', 'series')
),
actor_info AS (
    SELECT a.person_id, 
           a.name, 
           COUNT(ci.movie_id) AS movie_count 
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.person_id, a.name
),
movie_keywords AS (
    SELECT mk.movie_id, 
           STRING_AGG(k.keyword, ', ') AS keywords 
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT ft.title, 
       ft.production_year, 
       ft.kind, 
       ai.name AS actor_name, 
       ai.movie_count, 
       mk.keywords
FROM filtered_titles ft
JOIN complete_cast cc ON ft.title_id = cc.movie_id
JOIN actor_info ai ON cc.subject_id = ai.person_id
JOIN movie_keywords mk ON ft.title_id = mk.movie_id
WHERE ai.movie_count > 5
ORDER BY ft.production_year DESC, ft.title;