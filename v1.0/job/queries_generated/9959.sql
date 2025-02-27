WITH RecursiveTitleInfo AS (
    SELECT t.id AS title_id, t.title, t.production_year, c.name AS company_name, k.keyword, 
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
),
FilteredTitles AS (
    SELECT title_id, title, production_year, company_name
    FROM RecursiveTitleInfo
    WHERE keyword_rank <= 3
)
SELECT ft.title, ft.production_year, ft.company_name, COUNT(rc.id) AS cast_count, 
       ARRAY_AGG(DISTINCT ak.name) AS aka_names
FROM FilteredTitles ft
LEFT JOIN complete_cast cc ON ft.title_id = cc.movie_id
LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN person_info pi ON ak.person_id = pi.person_id
GROUP BY ft.title_id, ft.title, ft.production_year, ft.company_name
HAVING COUNT(rc.id) > 5
ORDER BY ft.production_year DESC, ft.title;
