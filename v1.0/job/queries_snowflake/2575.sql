WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(c.id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.person_id, r.role
    HAVING 
        COUNT(c.id) > 2
),
MovieCompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    fc.person_id,
    fc.role,
    COALESCE(mcc.company_count, 0) AS company_count,
    CASE 
        WHEN mcc.company_count IS NULL AND fc.cast_count > 5 THEN 'No Companies'
        WHEN mcc.company_count IS NOT NULL AND fc.cast_count > 5 THEN 'Multiple Companies'
        ELSE 'Single Company or Less'
    END AS company_status
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
LEFT JOIN 
    MovieCompanyCount mcc ON rm.movie_id = mcc.movie_id
WHERE 
    rm.title_rank <= 5
    AND (fc.role IS NOT NULL OR rm.production_year IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
