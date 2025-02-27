
WITH RankedMovies AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           COUNT(DISTINCT c.person_id) AS cast_count,
           RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT mi.movie_id, 
           STRING_AGG(mi.info, '; ') AS all_info
    FROM movie_info mi
    GROUP BY mi.movie_id
),
FilmCompanies AS (
    SELECT mc.movie_id, 
           STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
FilteredMovies AS (
    SELECT rm.movie_id, 
           rm.title, 
           rm.production_year, 
           rm.cast_count,
           COALESCE(mf.all_info, 'No Info') AS info,
           COALESCE(fc.companies, 'No Companies') AS companies
    FROM RankedMovies rm
    LEFT JOIN MovieInfo mf ON rm.movie_id = mf.movie_id
    LEFT JOIN FilmCompanies fc ON rm.movie_id = fc.movie_id
    WHERE rm.rank <= 5
)
SELECT f.movie_id, 
       f.title, 
       f.production_year, 
       f.cast_count,
       f.info,
       f.companies
FROM FilteredMovies f
ORDER BY f.production_year DESC, f.cast_count DESC;
