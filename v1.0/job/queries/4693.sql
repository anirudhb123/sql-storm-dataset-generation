
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year
), KeywordCounts AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
), CompanyStats AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT co.name) AS company_count, 
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
), CTE AS (
    SELECT 
        md.title_id, 
        md.title, 
        md.production_year, 
        md.cast_count,
        kc.keyword_count, 
        cs.company_count,
        cs.company_names,
        md.has_note_ratio
    FROM MovieDetails md
    LEFT JOIN KeywordCounts kc ON md.title_id = kc.movie_id
    LEFT JOIN CompanyStats cs ON md.title_id = cs.movie_id
)
SELECT 
    c.title_id, 
    c.title, 
    c.production_year, 
    c.cast_count,
    COALESCE(c.keyword_count, 0) AS keyword_count,
    COALESCE(c.company_count, 0) AS company_count,
    c.company_names,
    CASE 
        WHEN c.has_note_ratio > 0.5 THEN 'High Note Usage'
        ELSE 'Low Note Usage'
    END AS note_usage_category
FROM CTE c
ORDER BY c.production_year DESC, c.cast_count DESC
LIMIT 100
OFFSET 0;
