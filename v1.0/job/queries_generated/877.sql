WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    GROUP BY mt.id, mt.title, mt.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        cs.company_count,
        cs.company_names
    FROM RankedMovies rm
    LEFT JOIN CompanyStats cs ON rm.movie_title = cs.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    COALESCE(md.company_count, 0) AS company_count,
    CASE WHEN md.company_count IS NULL THEN 'No Companies' ELSE md.company_names END AS company_names
FROM MovieDetails md
WHERE md.rank <= 3
ORDER BY md.production_year DESC, md.cast_count DESC;
