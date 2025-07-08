
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),

CompanyContributions AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        SUM(CASE 
            WHEN ct.kind = 'Distributor' THEN 1 
            ELSE 0 
        END) AS distributor_count
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
    fm.title,
    fm.production_year,
    fm.total_cast,
    cc.companies,
    cc.distributor_count,
    (SELECT COUNT(DISTINCT ci2.person_id) 
     FROM cast_info ci2 
     WHERE ci2.movie_id = (SELECT MAX(movie_id) FROM movie_companies)) AS actors_in_last_movie,
    (SELECT MAX(production_year) 
     FROM aka_title 
     WHERE production_year > 2000) AS last_21st_century_movie
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyContributions cc ON fm.title = (SELECT title 
                                           FROM aka_title WHERE movie_id = cc.movie_id LIMIT 1)
WHERE 
    COALESCE(cc.distributor_count, 0) > 0 
    AND fm.production_year IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC;
