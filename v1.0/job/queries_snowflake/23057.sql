
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS movie_info,
        MIN(mi.note) AS min_note,
        MAX(mi.info_type_id) AS max_info_type
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT cn.id) AS company_count,
        MAX(ct.kind) AS highest_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mid.movie_info, 'No Info') AS movie_info,
    cd.company_names,
    cd.company_count,
    cd.highest_company_type,
    CASE 
        WHEN cd.company_count > 5 THEN 'Many Companies'
        WHEN cd.company_count BETWEEN 3 AND 5 THEN 'Some Companies'
        WHEN cd.company_count = 0 THEN 'No Companies'
        ELSE 'Few Companies'
    END AS company_category,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY rm.production_year DESC) AS production_year_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfoDetails mid ON rm.movie_id = mid.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    (mid.max_info_type IS NULL OR mid.max_info_type <> 0)
    AND (cd.company_count IS NULL OR cd.company_count > 0)
    AND rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title;
