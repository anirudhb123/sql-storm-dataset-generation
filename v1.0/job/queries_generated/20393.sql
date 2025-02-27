WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM title t
    WHERE t.production_year IS NOT NULL
    AND t.title IS NOT NULL 
),
DistinctKeywords AS (
    SELECT 
        DISTINCT k.keyword, 
        mk.movie_id
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL 
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM cast_info c
    GROUP BY c.movie_id
),
MoviesWithHighCast AS (
    SELECT 
        m.movie_id
    FROM CastCounts m
    WHERE m.cast_count > 10
),
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE cn.country_code IS NOT NULL
)
SELECT 
    rt.title, 
    rt.production_year, 
    rt.rn,
    COALESCE(CAST(CASTCounts.cast_count AS VARCHAR), 'No Cast') AS cast_count,
    ci.company_name,
    ci.company_type,
    COUNT(DISTINCT dk.keyword) AS keyword_count,
    CASE 
        WHEN rt.title_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM RankedTitles rt
LEFT JOIN MoviesWithHighCast mhc ON rt.production_year = mhc.movie_id
LEFT JOIN CastCounts AS CASTCounts ON mhc.movie_id = CASTCounts.movie_id
LEFT JOIN CompanyInfo ci ON mhc.movie_id = ci.movie_id
LEFT JOIN DistinctKeywords dk ON mhc.movie_id = dk.movie_id
GROUP BY rt.title, rt.production_year, rt.rn, CASTCounts.cast_count, ci.company_name, ci.company_type, rt.title_count
HAVING rt.production_year IS NOT NULL AND rt.title IS NOT NULL
ORDER BY rt.production_year DESC, popularity, rt.title;
