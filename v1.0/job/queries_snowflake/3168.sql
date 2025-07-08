
WITH MovieStatistics AS (
    SELECT 
        mt.title, 
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE 
            WHEN ci.nr_order IS NOT NULL THEN ci.nr_order 
            ELSE 0 
        END) AS avg_cast_order
    FROM aka_title mt
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE mt.production_year BETWEEN 1990 AND 2020
    GROUP BY mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast,
        avg_cast_order,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank
    FROM MovieStatistics
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.total_cast, 
    tm.avg_cast_order,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id IN (SELECT id FROM aka_title WHERE production_year = tm.production_year)) AS related_movie_count,
    COALESCE((SELECT LISTAGG(DISTINCT kw.keyword, ', ') 
              WITHIN GROUP (ORDER BY kw.keyword) 
              FROM movie_keyword mk 
              JOIN keyword kw ON mk.keyword_id = kw.id 
              WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)), 'No Keywords') AS keywords
FROM TopMovies tm
WHERE tm.rank <= 10
ORDER BY tm.production_year, total_cast DESC;
