WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
        JOIN complete_cast cc ON t.id = cc.movie_id
        JOIN cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count,
        cd.companies,
        cd.company_count
    FROM 
        RankedMovies r
        LEFT JOIN CompanyDetails cd ON r.title = cd.movie_id
    WHERE 
        r.rank <= 10
)
SELECT 
    COALESCE(tm.title, 'Unknown Title') AS movie_title,
    COALESCE(tm.production_year, 'N/A') AS year,
    COALESCE(tm.cast_count, 0) AS num_cast_members,
    COALESCE(tm.companies, 'No Companies') AS production_companies,
    COALESCE(tm.company_count, 0) AS num_production_companies
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.num_cast_members DESC;
