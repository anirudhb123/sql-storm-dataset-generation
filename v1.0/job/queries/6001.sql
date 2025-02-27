
WITH movie_details AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN aka_name ak ON cc.subject_id = ak.person_id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.title, t.production_year, c.name
)
SELECT
    md.movie_title,
    md.production_year,
    md.company_name,
    md.aka_names,
    md.keywords
FROM movie_details md
ORDER BY md.production_year DESC, md.movie_title;
