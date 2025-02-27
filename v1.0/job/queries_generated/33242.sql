WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           1 AS level,
           m.id AS root_movie_id
    FROM aka_title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.level + 1,
           mh.root_movie_id
    FROM movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE m.production_year IS NOT NULL
),
ranked_cast AS (
    SELECT c.movie_id,
           a.name AS actor_name,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
),
movie_keywords AS (
    SELECT mk.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_details AS (
    SELECT mc.movie_id,
           cn.name AS company_name,
           ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
movies_with_keywords AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           COALESCE(mk.keywords, 'No keywords') AS keywords,
           c.actor_name,
           c.role_rank
    FROM movie_hierarchy mh
    LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN ranked_cast c ON mh.movie_id = c.movie_id
)
SELECT mw.title,
       mw.production_year,
       mw.keywords,
       mw.actor_name,
       mw.role_rank,
       COALESCE(cd.company_name, 'Unknown Company') AS production_company,
       COALESCE(cd.company_type, 'Not Specified') AS company_type
FROM movies_with_keywords mw
LEFT JOIN company_details cd ON mw.movie_id = cd.movie_id
WHERE mw.production_year >= 2000
ORDER BY mw.production_year DESC, mw.role_rank, mw.title;

