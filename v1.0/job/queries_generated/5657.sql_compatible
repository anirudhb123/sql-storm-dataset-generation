
WITH movie_info_cte AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           m.kind_id,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY m.id, m.title, m.production_year, m.kind_id
),
cast_info_cte AS (
    SELECT c.movie_id,
           STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
           STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
)
SELECT m.movie_id,
       m.title,
       m.production_year,
       m.keywords,
       m.company_names,
       c.cast_names,
       c.roles
FROM movie_info_cte m
LEFT JOIN cast_info_cte c ON m.movie_id = c.movie_id
WHERE m.production_year >= 2000
ORDER BY m.production_year DESC, m.title ASC
LIMIT 50;
