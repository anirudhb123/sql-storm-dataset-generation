WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title mt
    JOIN cast_info c ON mt.id = c.movie_id
    WHERE mt.production_year IS NOT NULL
    GROUP BY mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM RankedMovies
    WHERE rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS all_actors,
        COALESCE(AVG(mi.info), 'No Info') AS average_info,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM TopMovies tm
    LEFT JOIN cast_info ci ON tm.title = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_info mi ON tm.title = mi.movie_id
    LEFT JOIN movie_keyword mk ON tm.title = mk.movie_id
    GROUP BY tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.all_actors,
    md.average_info,
    md.keyword_count,
    (CASE 
        WHEN md.keyword_count > 5 THEN 'Highly Tagged' 
        WHEN md.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged' 
        ELSE 'Barely Tagged' 
    END) AS tagging_status
FROM MovieDetails md
ORDER BY md.production_year DESC, md.keyword_count DESC;
