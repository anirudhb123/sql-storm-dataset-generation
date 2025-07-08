WITH MovieAggregate AS (
    SELECT 
        mt.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(movie_info.info_type_id) AS avg_info_type
    FROM aka_title mt
    LEFT JOIN cast_info c ON mt.id = c.movie_id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN movie_info movie_info ON mt.id = movie_info.movie_id
    WHERE mt.production_year IS NOT NULL AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY mt.production_year
),
PopularMovies AS (
    SELECT 
        mt.title,
        mt.production_year, 
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM aka_title mt
    JOIN cast_info c ON mt.id = c.movie_id
    GROUP BY mt.title, mt.production_year
    HAVING COUNT(c.person_id) > 10
)
SELECT 
    ma.production_year,
    ma.actor_count,
    ma.company_count,
    ma.avg_info_type,
    pm.title AS popular_movie_title,
    pm.rank
FROM MovieAggregate ma
LEFT JOIN PopularMovies pm ON ma.production_year = pm.production_year
WHERE ma.actor_count > 5 AND ma.company_count IS NOT NULL
ORDER BY ma.production_year DESC, pm.rank ASC;
