
WITH ActorMovies AS (
    SELECT a.person_id, 
           a.name, 
           COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.person_id, a.name
),
MovieStatistics AS (
    SELECT t.id AS movie_id, 
           t.title,
           t.production_year,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           AVG(CASE WHEN t.production_year IS NOT NULL THEN EXTRACT(YEAR FROM TIMESTAMP '2024-10-01 12:34:56') - t.production_year ELSE NULL END) AS avg_years_since_release
    FROM aka_title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT mk.movie_id, 
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieCompanyData AS (
    SELECT mc.movie_id, 
           STRING_AGG(DISTINCT CONCAT(cn.name, ' (', ct.kind, ')'), ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
FinalMovieStats AS (
    SELECT ms.movie_id, 
           ms.title,
           ms.production_year,
           ms.cast_count,
           ms.avg_years_since_release,
           COALESCE(ks.keywords, 'No Keywords') AS keywords,
           COALESCE(cd.companies, 'No Companies') AS companies
    FROM MovieStatistics ms
    LEFT JOIN KeywordStats ks ON ms.movie_id = ks.movie_id
    LEFT JOIN MovieCompanyData cd ON ms.movie_id = cd.movie_id
)

SELECT f.title, 
       f.production_year, 
       f.cast_count, 
       f.avg_years_since_release, 
       f.keywords,
       f.companies,
       (SELECT MAX(ci2.person_role_id) 
        FROM cast_info ci2 
        WHERE ci2.movie_id = f.movie_id AND ci2.note IS NULL) AS max_role_id_by_note
FROM FinalMovieStats f
WHERE f.cast_count > 0
AND f.avg_years_since_release > (SELECT AVG(years_since_release) 
                                  FROM (SELECT EXTRACT(YEAR FROM TIMESTAMP '2024-10-01 12:34:56') - ms.production_year AS years_since_release
                                          FROM MovieStatistics ms) AS avg_by_year)
ORDER BY f.production_year DESC, 
         f.title ASC
LIMIT 10;
