WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT k.id) AS total_keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.total_keywords,
        rm.companies
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 5 AND rm.total_cast > 10
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.total_keywords,
    fm.companies
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.total_cast DESC;