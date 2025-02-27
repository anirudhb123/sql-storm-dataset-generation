WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ak.name AS actor_name,
        COUNT(c.id) AS cast_count
    FROM aka_title a
    JOIN cast_info c ON a.id = c.movie_id
    JOIN aka_name ak ON c.person_id = ak.person_id
    WHERE a.production_year BETWEEN 2000 AND 2023
    GROUP BY a.id, a.title, a.production_year, ak.name
),
KeywordMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(mk.id) AS keyword_count
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2023
    GROUP BY m.id, m.title
),
MovieDetails AS (
    SELECT 
        r.title,
        r.production_year,
        r.actor_name,
        r.cast_count,
        km.keyword_count
    FROM RankedMovies r
    LEFT JOIN KeywordMovies km ON r.title = km.title
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.cast_count,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count IS NULL THEN 'No Keywords'
        WHEN md.keyword_count = 0 THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM MovieDetails md
WHERE md.cast_count > 3
ORDER BY md.production_year DESC, md.cast_count DESC, md.keyword_count DESC;

This SQL query benchmarks string processing by generating a list of movies from the `aka_title` table, their respective actors from the `aka_name` table, and the keyword counts from the `movie_keyword` table. It also filters to ensure that only movies with more than three cast members are displayed, along with an additional column that describes the status of keywords associated with each movie. The result is ordered by production year, cast count, and keyword count for efficient analysis.
