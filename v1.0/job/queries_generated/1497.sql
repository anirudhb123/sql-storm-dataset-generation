WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        count(DISTINCT ci.role_id) AS role_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_details AS (
    SELECT 
        mt.movie_id,
        MAX(CASE WHEN it.info_type_id = 1 THEN it.info END) AS director,
        MAX(CASE WHEN it.info_type_id = 2 THEN it.info END) AS producer,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_info mi
    JOIN movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mt.movie_id
)
SELECT 
    at.title,
    at.production_year,
    cwi.role_count,
    md.director,
    md.producer,
    md.keyword_count,
    COALESCE(aka.name, 'Unknown') AS actor_name
FROM aka_title at
LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id 
LEFT JOIN movie_details md ON at.movie_id = md.movie_id
LEFT JOIN cast_info cwi ON at.movie_id = cwi.movie_id
LEFT JOIN aka_name aka ON cwi.person_id = aka.person_id
WHERE at.production_year >= 2000 
    AND at.id IN (SELECT title_id FROM ranked_titles WHERE year_rank <= 10)
    AND (md.keyword_count > 5 OR md.director IS NOT NULL)
ORDER BY at.production_year DESC, cwi.role_count DESC;
