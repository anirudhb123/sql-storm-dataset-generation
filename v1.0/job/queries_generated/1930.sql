WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    WHERE at.production_year IS NOT NULL
    GROUP BY at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM RankedMovies rm
    WHERE rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COALESCE(mci.company_name, 'No Company') AS company_name
    FROM TopMovies tm
    LEFT JOIN movie_keyword mk ON tm.title = mk.movie_id
    LEFT JOIN movie_companies mco ON tm.title = mco.movie_id
    LEFT JOIN company_name mci ON mco.company_id = mci.id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.company_name,
    COUNT(pi.info) AS person_info_count,
    STRING_AGG(DISTINCT pi.info, ', ') AS info_details
FROM MovieDetails md
LEFT JOIN person_info pi ON pi.person_id IN (
    SELECT DISTINCT ci.person_id 
    FROM cast_info ci 
    WHERE ci.movie_id IN (SELECT title FROM TopMovies)
)
GROUP BY md.title, md.production_year, md.keyword, md.company_name
ORDER BY md.production_year DESC, md.total_cast DESC;
