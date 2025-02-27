WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MoviesAndCompanies AS (
    SELECT 
        t.title,
        c.name AS company_name,
        mt.kind AS company_type,
        COUNT(mci.movie_id) AS company_count
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN company_type mt ON mt.id = mc.company_type_id
    WHERE t.production_year > 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
    GROUP BY t.title, c.name, mt.kind
),
SubQuery AS (
    SELECT
        title_id,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM cast_info cc
    JOIN title t ON t.id = cc.movie_id
    GROUP BY title_id
),
FinalSelect AS (
    SELECT 
        m.title,
        m.company_name,
        m.company_type,
        COALESCE(s.cast_count, 0) AS cast_count,
        CURRENT_DATE - INTERVAL '1 year' AS report_date
    FROM MoviesAndCompanies m
    LEFT JOIN SubQuery s ON s.title_id = m.title_id
    WHERE m.company_count > 1
    ORDER BY m.company_name DESC, cast_count DESC
)
SELECT 
    title,
    company_name,
    company_type,
    cast_count,
    CASE 
        WHEN cast_count IS NULL THEN 'No cast information available'
        WHEN cast_count = 0 THEN 'No cast members found'
        ELSE 'Cast members present'
    END AS cast_info_status,
    MD5(title || company_name || company_type) AS unique_identifier
FROM FinalSelect
WHERE CAST(cast_count AS INTEGER) > 0
UNION 
SELECT 
    t.title,
    'N/A' AS company_name,
    'N/A' AS company_type,
    0 AS cast_count,
    'No cast information available' AS cast_info_status,
    MD5(t.title) AS unique_identifier
FROM title t
WHERE t.production_year < 2000 AND NOT EXISTS (SELECT 1 FROM cast_info WHERE movie_id = t.id)
ORDER BY report_date DESC, title ASC
LIMIT 100;
