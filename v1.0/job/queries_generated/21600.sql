WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           COALESCE(m.episode_of_id, mt.id) AS parent_id, 
           0 AS depth 
    FROM aka_title mt 
    LEFT JOIN aka_title m ON mt.episode_of_id = m.id 
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    UNION ALL 
    SELECT m.id AS movie_id, 
           m.title, 
           COALESCE(mt.episode_of_id, m.id) AS parent_id, 
           depth + 1 
    FROM aka_title m 
    JOIN MovieHierarchy mt ON m.episode_of_id = mt.movie_id
),
FilteredMovies AS (
    SELECT mh.movie_id, 
           mh.title, 
           mh.depth, 
           STRING_AGG(DISTINCT c.role_id::text, ', ') AS roles, 
           COUNT(DISTINCT ci.person_id) AS total_cast 
    FROM MovieHierarchy mh 
    LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id 
    LEFT JOIN role_type c ON ci.role_id = c.id 
    GROUP BY mh.movie_id, mh.title, mh.depth
),
RankedMovies AS (
    SELECT *, 
           RANK() OVER (PARTITION BY depth ORDER BY total_cast DESC) AS rank 
    FROM FilteredMovies 
)
SELECT f.title AS movie_title,
       f.depth AS hierarchy_depth,
       COALESCE(f.roles, 'No roles') AS cast_roles, 
       COALESCE(f.total_cast, 0) AS number_of_cast,
       CASE 
           WHEN f.total_cast IS NULL OR f.total_cast = 0 THEN 'Unknown' 
           ELSE 'Known' 
       END AS cast_status
FROM RankedMovies f
WHERE f.rank <= 5 
AND (f.depth < 2 OR f.total_cast > 5)
ORDER BY f.depth, f.total_cast DESC
LIMIT 100;
