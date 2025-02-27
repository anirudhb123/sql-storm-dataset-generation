WITH RECURSIVE CompanyHierarchy AS (
    SELECT c.id AS company_id, c.name AS company_name, c.country_code, 
           0 AS level
    FROM company_name c
    WHERE c.country_code IS NOT NULL
    
    UNION ALL
    
    SELECT c.id AS company_id, c.name AS company_name, c.country_code, 
           ch.level + 1
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN CompanyHierarchy ch ON mc.movie_id = ch.company_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CombinedMovieData AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.roles_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM MovieDetails md
    LEFT JOIN MovieKeywords mk ON md.movie_id = mk.movie_id
)
SELECT 
    c.company_id,
    c.company_name,
    c.country_code,
    m.title AS movie_title,
    m.production_year,
    m.cast_count,
    m.roles_count,
    m.keywords
FROM CompanyHierarchy c
LEFT JOIN movie_companies mc ON c.company_id = mc.company_id
LEFT JOIN CombinedMovieData m ON mc.movie_id = m.movie_id
WHERE c.level < 3
ORDER BY c.company_name, m.production_year DESC
LIMIT 100;
