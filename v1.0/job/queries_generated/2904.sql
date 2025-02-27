WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.person_id) AS cast_size
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.company_count, 0) AS total_companies,
    cd.cast_names,
    cd.cast_size,
    CASE 
        WHEN cd.cast_size > 5 THEN 'Large Cast' 
        WHEN cd.cast_size IS NULL THEN 'No Cast'
        ELSE 'Small Cast' 
    END AS cast_description
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_title <= 3
ORDER BY 
    rm.production_year DESC, rm.title;
