WITH RecursiveTitle AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rounnd(count(ct.id) * 1.0/ 5) AS avg_cast_size
    FROM RecursiveTitle rt
    LEFT JOIN cast_info ct ON ct.movie_id = rt.title_id
    GROUP BY rt.title_id
    HAVING AVG(CASE WHEN ct.person_id IS NOT NULL THEN 1 ELSE 0 END) > 0.5
),
CompanyTitles AS (
    SELECT 
        mt.movie_id,
        c.name AS company_name,
        COUNT(m.id) AS title_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN aka_title at ON mc.movie_id = at.movie_id
    JOIN title m ON at.movie_id = m.id
    WHERE c.name IS NOT NULL 
    GROUP BY mt.movie_id, c.name
),
MysteryMovies AS (
    SELECT 
        b.title,
        (SELECT COUNT(DISTINCT m.id)
         FROM movie_keyword mk
         JOIN keyword k ON mk.keyword_id = k.id
         WHERE k.keyword LIKE 'mystery%' AND mk.movie_id = b.title_id) AS mystery_keywords_count
    FROM FilteredTitles b
    WHERE b.avg_cast_size > 2
),
FinalOutput AS (
    SELECT 
        ft.title,
        ft.production_year,
        ct.company_name,
        mm.mystery_keywords_count
    FROM FilteredTitles ft
    LEFT JOIN CompanyTitles ct ON ft.title_id = ct.movie_id
    LEFT JOIN MysteryMovies mm ON ft.title_id = mm.title_id
    WHERE (mm.mystery_keywords_count IS NULL OR mm.mystery_keywords_count > 0)
    ORDER BY ft.production_year DESC, ft.title
)
SELECT 
    title,
    production_year,
    COALESCE(company_name, 'Independent') AS company_type,
    COALESCE(mystery_keywords_count, 0) AS mystery_keyword_count
FROM FinalOutput
WHERE EXISTS (
    SELECT 1 
    FROM aka_title at 
    WHERE at.title_id = FinalOutput.title_id 
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
)
OR NOT EXISTS (
    SELECT 1
    FROM movie_info mi 
    WHERE mi.movie_id = FinalOutput.title_id 
    AND mi.info LIKE '%award%'
)
LIMIT 50 OFFSET 10;
