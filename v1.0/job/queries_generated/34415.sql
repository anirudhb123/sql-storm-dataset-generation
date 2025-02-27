WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title AS movie_title, 
           m.production_year,
           1 AS level
    FROM aka_title m
    WHERE m.kind_id = 1  -- Assuming 1 is for main titles

    UNION ALL

    SELECT m.id AS movie_id, 
           m.title AS movie_title, 
           m.production_year,
           mh.level + 1 AS level
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id 
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
LatestMovies AS (
    SELECT movie_id, 
           movie_title, 
           production_year,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_id DESC) AS rn
    FROM MovieHierarchy
),
PopularMovies AS (
    SELECT mv.movie_id,
           mv.movie_title, 
           mv.production_year,
           COUNT(cc.movie_id) AS total_cast,
           AVG(CASE 
               WHEN cc.nr_order IS NULL THEN 0 
               ELSE cc.nr_order 
           END) AS avg_order
    FROM LatestMovies mv
    LEFT JOIN cast_info cc ON mv.movie_id = cc.movie_id
    GROUP BY mv.movie_id, mv.movie_title, mv.production_year
),
FilteredPopularMovies AS (
    SELECT movie_id, 
           movie_title, 
           production_year, 
           total_cast,
           avg_order
    FROM PopularMovies
    WHERE total_cast > 5 AND production_year > 2000
),
MovieInfo AS (
    SELECT m.movie_id, 
           m.movie_title, 
           m.production_year,
           mi.info,
           ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY mi.info_type_id) AS info_rank
    FROM FilteredPopularMovies m
    LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
)
SELECT 
    fpm.movie_id,
    fpm.movie_title,
    fpm.production_year,
    fpm.total_cast,
    fpm.avg_order,
    STRING_AGG(mi.info, ', ') AS info_summary
FROM FilteredPopularMovies fpm
LEFT JOIN MovieInfo mi ON fpm.movie_id = mi.movie_id AND mi.info_rank <= 3
GROUP BY fpm.movie_id, fpm.movie_title, fpm.production_year, fpm.total_cast, fpm.avg_order
ORDER BY fpm.production_year DESC, fpm.total_cast DESC;
