WITH cast_aggregate AS (
    SELECT ci.movie_id,
           STRING_AGG(DISTINCT ka.name, ', ') AS actor_names,
           STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM cast_info ci
    JOIN aka_name ka ON ci.person_id = ka.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id
),
movie_details AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           COALESCE(company cname.name, 'Unknown') AS company_name
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cname ON mc.company_id = cname.id
    GROUP BY m.id
),
full_movie_report AS (
    SELECT md.movie_id,
           md.title,
           md.production_year,
           md.keywords,
           ca.actor_names,
           ca.roles,
           md.company_name
    FROM movie_details md
    LEFT JOIN cast_aggregate ca ON md.movie_id = ca.movie_id
)
SELECT fmr.movie_id,
       fmr.title,
       fmr.production_year,
       fmr.keywords,
       fmr.actor_names,
       fmr.roles,
       fmr.company_name
FROM full_movie_report fmr
WHERE fmr.production_year >= 2000
ORDER BY fmr.production_year DESC, fmr.title;
