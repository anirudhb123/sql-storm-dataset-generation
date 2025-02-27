WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        r.movie_id,
        r.movie_title,
        r.production_year,
        r.cast_count
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        STRING_AGG(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info) AS movie_infos
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    COALESCE(cd.companies, 'No companies') AS companies,
    COALESCE(cd.company_types, 'No types') AS company_types,
    COALESCE(mi.movie_infos, 'No info') AS movie_infos
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON tm.movie_id = mi.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
