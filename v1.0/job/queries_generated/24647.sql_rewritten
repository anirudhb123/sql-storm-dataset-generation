WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        DENSE_RANK() OVER (ORDER BY t.production_year) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
FilteredMovies AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        cs.total_cast,
        cs.cast_with_notes,
        ci.company_name,
        ci.company_type,
        ci.num_companies,
        RANK() OVER (PARTITION BY mt.year_rank ORDER BY cs.total_cast DESC) AS cast_rank
    FROM 
        RankedTitles mt
    LEFT JOIN 
        CastDetails cs ON mt.title_id = cs.movie_id
    LEFT JOIN 
        CompanyInfo ci ON mt.title_id = ci.movie_id
)

SELECT 
    fm.title,
    fm.production_year, 
    fm.total_cast,
    fm.cast_with_notes,
    COUNT(DISTINCT fm.company_name) AS unique_companies,
    MAX(CASE WHEN fm.cast_rank IS NULL THEN 'No Cast Available' ELSE 'Has Cast' END) AS cast_status,
    STRING_AGG(DISTINCT fm.company_type, ', ') AS company_types,
    COALESCE(CAST(SUM(fm.cast_with_notes) AS VARCHAR), '0') AS notes_summary
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year >= 2000 
GROUP BY 
    fm.title, fm.production_year, fm.total_cast, fm.cast_with_notes
ORDER BY 
    fm.production_year DESC, fm.total_cast DESC
LIMIT 50
OFFSET 0;