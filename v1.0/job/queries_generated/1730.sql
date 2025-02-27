WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

MoviesWithInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mi.info AS movie_info
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
)

SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    COALESCE(mc.company_name, 'Unknown') AS company_name,
    COALESCE(mc.company_count, 0) AS total_companies,
    mw.movie_info,
    CASE 
        WHEN mw.rank <= 5 THEN 'Top Production'
        ELSE 'Regular Production'
    END AS production_status
FROM 
    MoviesWithInfo mw
LEFT JOIN 
    MovieCompanies mc ON mw.movie_id = mc.movie_id
WHERE 
    mw.production_year >= 2000
    AND (mw.movie_info IS NULL OR mw.movie_info NOT LIKE '%no data%')
ORDER BY 
    mw.production_year DESC, 
    mw.rank;
