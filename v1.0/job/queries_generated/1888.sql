WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.title, t.production_year
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
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        der.title AS related_movie
    FROM TopMovies tm
    LEFT JOIN movie_keyword mk ON tm.title = (SELECT title FROM title WHERE id = mk.movie_id)
    LEFT JOIN movie_companies mc ON mc.movie_id = (SELECT id FROM title WHERE title = tm.title)
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_link ml ON ml.movie_id = (SELECT id FROM title WHERE title = tm.title)
    LEFT JOIN title der ON ml.linked_movie_id = der.id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.company_name,
    md.related_movie,
    COUNT(DISTINCT ci.person_id) AS distinct_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM MovieDetails md
LEFT JOIN cast_info ci ON md.title = (SELECT title FROM title WHERE id = ci.movie_id)
LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
GROUP BY md.title, md.production_year, md.keyword, md.company_name, md.related_movie
HAVING COUNT(DISTINCT ci.person_id) > 0
ORDER BY md.production_year DESC, md.title;
