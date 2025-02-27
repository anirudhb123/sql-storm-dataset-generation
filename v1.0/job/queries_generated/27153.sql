WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS alias_names,
        c.character_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM title t
    LEFT JOIN aka_title akt ON t.id = akt.movie_id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN char_name c ON ci.person_id = c.imdb_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, c.character_name
),
company_details AS (
    SELECT 
        t.id AS title_id,
        GROUP_CONCAT(DISTINCT co.name) AS company_names,
        GROUP_CONCAT(DISTINCT co.country_code) AS company_countries
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name co ON mc.company_id = co.id
    GROUP BY t.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.alias_names,
    md.character_name,
    md.keywords,
    cd.company_names,
    cd.company_countries
FROM movie_details md
JOIN company_details cd ON md.title_id = cd.title_id
WHERE md.keywords LIKE '%action%'
  AND md.production_year >= 2000
ORDER BY md.production_year DESC, md.movie_title;
