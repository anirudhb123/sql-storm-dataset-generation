WITH RECURSIVE movie_hierarchy AS (
    SELECT title.id AS movie_id, title.title, title.production_year, title.kind_id, 
           ARRAY[title.title] AS title_path
    FROM title
    WHERE title.production_year >= 2000
    UNION ALL
    SELECT mk.linked_movie_id, t.title, t.production_year, t.kind_id, 
           mh.title_path || t.title
    FROM movie_link mk
    JOIN title t ON mk.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON mk.movie_id = mh.movie_id
),
actor_data AS (
    SELECT a.name AS actor_name, c.movie_id, t.title, t.production_year
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN title t ON c.movie_id = t.id
    WHERE t.production_year BETWEEN 2010 AND 2020
),
company_data AS (
    SELECT cn.name AS company_name, mc.movie_id
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code = 'USA'
),
keyword_data AS (
    SELECT mk.movie_id, k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword LIKE '%action%'
)
SELECT mh.movie_id AS movie_id,
       mh.title,
       mh.production_year,
       ad.actor_name,
       cd.company_name,
       kd.keyword
FROM movie_hierarchy mh
LEFT JOIN actor_data ad ON mh.movie_id = ad.movie_id
LEFT JOIN company_data cd ON mh.movie_id = cd.movie_id
LEFT JOIN keyword_data kd ON mh.movie_id = kd.movie_id
ORDER BY mh.production_year DESC, mh.title;
