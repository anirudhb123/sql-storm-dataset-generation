WITH movie_keywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
cast_details AS (
    SELECT ci.movie_id, STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
movie_info_extended AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           mk.keywords, 
           cd.cast_names, 
           mt.kind AS movie_type, 
           STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM aka_title m
    JOIN movie_info mi ON m.id = mi.movie_id
    JOIN kind_type mt ON m.kind_id = mt.id
    LEFT JOIN movie_keywords mk ON m.id = mk.movie_id
    LEFT JOIN cast_details cd ON m.id = cd.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    GROUP BY m.id, m.title, m.production_year, mk.keywords, cd.cast_names, mt.kind
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    cast_names,
    movie_type,
    COALESCE(companies, 'No companies involved') AS companies
FROM movie_info_extended
WHERE production_year >= 2000
ORDER BY production_year DESC, title;
