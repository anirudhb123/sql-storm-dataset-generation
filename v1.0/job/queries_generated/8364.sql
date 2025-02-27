WITH MovieDetails AS (
    SELECT t.title, t.production_year, c.name AS company_name, r.role AS role
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE t.production_year BETWEEN 2000 AND 2020
),
KeywordDetails AS (
    SELECT m.movie_id, GROUP_CONCAT(k.keyword) AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
InfoDetails AS (
    SELECT mi.movie_id, GROUP_CONCAT(mi.info) AS info_details
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.role,
    kd.keywords,
    id.info_details
FROM MovieDetails md
LEFT JOIN KeywordDetails kd ON md.title = (SELECT title FROM title WHERE id = kd.movie_id)
LEFT JOIN InfoDetails id ON md.title = (SELECT title FROM title WHERE id = id.movie_id)
ORDER BY md.production_year DESC, md.title;
