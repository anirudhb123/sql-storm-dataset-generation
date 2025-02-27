WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL), 'No Cast') AS cast_names,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_names,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.movie_rank <= 3
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalJoin AS (
    SELECT 
        tcm.movie_id,
        tcm.title,
        tcm.production_year,
        tcm.cast_names,
        tcm.cast_count,
        COALESCE(ci.companies, 'No Companies') AS companies
    FROM 
        TopCastMovies tcm
    LEFT JOIN 
        CompanyInfo ci ON tcm.movie_id = ci.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_names,
    f.cast_count,
    f.companies,
    CASE 
        WHEN f.cast_count = 0 THEN 'No Cast'
        ELSE (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = f.movie_id)
    END AS keyword_count,
    EXTRACT(YEAR FROM NOW()) - f.production_year AS years_since_release
FROM 
    FinalJoin f
WHERE 
    f.production_year > 2000
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
