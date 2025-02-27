
WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title,
           m.production_year,
           COALESCE(t.note, 'No note') AS title_note,
           ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rn
    FROM aka_title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    LEFT JOIN aka_title t ON ml.linked_movie_id = t.id
    WHERE m.production_year IS NOT NULL OR EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Distribution')
    )
),
TopMovies AS (
    SELECT mh.movie_id, 
           mh.title,
           mh.production_year,
           mh.title_note,
           SUM(CASE 
                   WHEN ci.role_id IS NOT NULL THEN 1 
                   ELSE 0 
               END) AS total_cast
    FROM MovieHierarchy mh
    LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY mh.movie_id, mh.title, mh.production_year, mh.title_note
    HAVING SUM(CASE 
                   WHEN ci.role_id IS NOT NULL THEN 1 
                   ELSE 0 
               END) > 5
),
RankedMovies AS (
    SELECT tm.*,
           RANK() OVER (ORDER BY tm.production_year DESC) AS year_rank,
           DENSE_RANK() OVER (ORDER BY tm.total_cast DESC) AS cast_rank
    FROM TopMovies tm
)
SELECT rm.movie_id,
       rm.title,
       rm.production_year,
       rm.title_note,
       rm.total_cast,
       CASE 
           WHEN rm.year_rank = 1 THEN 'Latest Release'
           WHEN rm.cast_rank = 1 THEN 'Most Cast Members'
           ELSE 'Regular Movie' 
       END AS movie_category,
       (SELECT COUNT(*) 
        FROM movie_keyword mk 
        WHERE mk.movie_id = rm.movie_id) AS keyword_count,
       (SELECT STRING_AGG(k.keyword, ', ') 
        FROM movie_keyword mk 
        JOIN keyword k ON mk.keyword_id = k.id 
        WHERE mk.movie_id = rm.movie_id) AS keywords
FROM RankedMovies rm
WHERE rm.total_cast > (SELECT AVG(total_cast) FROM TopMovies)
    OR rm.production_year IS NULL
ORDER BY rm.production_year DESC, rm.total_cast DESC;
