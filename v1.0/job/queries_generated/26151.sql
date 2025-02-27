WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_companies
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name co ON mc.company_id = co.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
FilteredTitles AS (
    SELECT *
    FROM RankedTitles
    WHERE rank_by_companies <= 5
)
SELECT 
    ft.title_id,
    ft.title,
    ft.production_year,
    ft.movie_kind,
    ft.companies,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM FilteredTitles ft
LEFT JOIN cast_info ci ON ft.title_id = ci.movie_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
GROUP BY ft.title_id, ft.title, ft.production_year, ft.movie_kind, ft.companies
ORDER BY ft.production_year DESC, total_cast DESC;
