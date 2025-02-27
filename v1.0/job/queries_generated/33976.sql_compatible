
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           CAST(NULL AS integer) AS parent_id, 
           0 AS level
    FROM aka_title m
    WHERE m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT m.id, 
           m.title, 
           m.production_year, 
           h.movie_id AS parent_id, 
           h.level + 1
    FROM aka_title m
    JOIN movie_hierarchy h ON m.episode_of_id = h.movie_id
),
cast_summary AS (
    SELECT ci.movie_id,
           COUNT(ci.person_id) AS total_cast,
           STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
yearly_production AS (
    SELECT production_year, 
           COUNT(*) AS movies_count
    FROM aka_title
    GROUP BY production_year
),
filtered_movies AS (
    SELECT mh.movie_id, 
           mh.title, 
           mh.production_year, 
           cs.total_cast, 
           cs.cast_names
    FROM movie_hierarchy mh
    LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
    WHERE mh.production_year = (SELECT MAX(production_year) FROM aka_title)
),
final_benchmark AS (
    SELECT f.movie_id,
           f.title,
           COALESCE(f.total_cast, 0) AS total_cast,
           f.cast_names,
           COALESCE(y.movies_count, 0) AS movies_count_this_year
    FROM filtered_movies f
    LEFT JOIN yearly_production y ON f.production_year = y.production_year
)
SELECT fb.movie_id,
       fb.title,
       fb.total_cast,
       fb.cast_names,
       fb.movies_count_this_year,
       LEAD(fb.movies_count_this_year) OVER (ORDER BY fb.movie_id) AS next_year_movies_count,
       CASE 
           WHEN fb.total_cast > 10 THEN 'Large Cast'
           WHEN fb.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
           ELSE 'Small Cast'
       END AS cast_size_category
FROM final_benchmark fb
ORDER BY fb.movie_id;
