
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ri.info, 'No info available') AS additional_info,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title m
    LEFT JOIN 
        movie_info ri ON m.id = ri.movie_id AND ri.info_type_id = (SELECT MIN(id) FROM info_type) 
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        m.id, m.title, ri.info
),
MoviesWithCompanies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.additional_info,
        fm.cast_count,
        cm.company_name,
        cm.company_type
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CompanyMovies cm ON fm.movie_id = cm.movie_id
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.additional_info,
    mwc.cast_count,
    mwc.company_name,
    mwc.company_type,
    (SELECT 
         STRING_AGG(DISTINCT ak.name, ', ') 
     FROM 
         aka_name ak 
     WHERE 
         ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mwc.movie_id)) AS cast_names
FROM 
    MoviesWithCompanies mwc
WHERE 
    mwc.cast_count > 5
ORDER BY 
    mwc.cast_count DESC, 
    mwc.title ASC;
