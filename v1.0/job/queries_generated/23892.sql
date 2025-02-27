WITH RecursiveCompany AS (
    SELECT c.id AS company_id, c.name, mc.movie_id, mc.company_type_id, 1 AS level
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    WHERE c.country_code = 'USA'

    UNION ALL

    SELECT c.id AS company_id, c.name, mc.movie_id, mc.company_type_id, r.level + 1
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN RecursiveCompany r ON mc.movie_id = r.movie_id 
    WHERE r.level < 5  -- Limit recursion to 5 levels deep
),
FilmDetails AS (
    SELECT 
        t.title,
        t.production_year,
        MAX(aka.name) AS aka_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM aka_title t
    LEFT JOIN aka_name aka ON aka.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year IS NOT NULL AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 's%')
    GROUP BY t.id
),
FinalReport AS (
    SELECT 
        fd.title,
        fd.production_year,
        fd.aka_name,
        fd.cast_count,
        fd.keywords,
        COALESCE(r.name, 'Unknown') AS main_company,
        COALESCE(mc.note, 'No notes') AS company_notes
    FROM FilmDetails fd
    LEFT JOIN RecursiveCompany r ON r.movie_id = (SELECT DISTINCT id FROM aka_title WHERE title = fd.title LIMIT 1)
    LEFT JOIN movie_companies mc ON mc.movie_id = (SELECT DISTINCT id FROM aka_title WHERE title = fd.title LIMIT 1)
    WHERE fd.cast_count > 5
)

SELECT 
    fr.title,
    fr.production_year,
    fr.aka_name,
    fr.cast_count,
    fr.keywords,
    fr.main_company,
    fr.company_notes
FROM FinalReport fr
WHERE fr.production_year BETWEEN 2000 AND 2023
ORDER BY fr.production_year DESC, fr.cast_count DESC
LIMIT 100;
