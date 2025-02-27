WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL AND t.title IS NOT NULL
),
CastSummary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_cast_count,
        STRING_AGG(DISTINCT a.name, ', ' ORDER BY a.name) AS cast_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    r.title,
    r.production_year,
    cs.unique_cast_count,
    cs.cast_names,
    cd.company_name,
    cd.company_type,
    cd.company_rank,
    CASE 
        WHEN cs.unique_cast_count > 5 THEN 'Large Cast'
        WHEN cs.unique_cast_count IS NULL THEN 'No Cast'
        ELSE 'Small Cast'
    END AS cast_category,
    COALESCE(cd.company_name, 'Independent') AS affiliation_source
FROM RankedMovies r
LEFT JOIN CastSummary cs ON r.title_id = cs.movie_id
LEFT JOIN CompanyDetails cd ON r.title_id = cd.movie_id
WHERE 
    (cd.company_type IS NOT NULL OR r.production_year < 2000)
    AND (cs.unique_cast_count IS NULL OR cs.unique_cast_count > 3)
    AND (r.year_rank <= 5 OR cd.company_rank <= 3)
ORDER BY r.production_year DESC, r.title;
