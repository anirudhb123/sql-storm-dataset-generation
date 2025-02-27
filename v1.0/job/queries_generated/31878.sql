WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           1 AS depth
    FROM aka_title m
    WHERE m.production_year <= 2000
    
    UNION ALL

    SELECT m.id, 
           m.title, 
           m.production_year, 
           mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id 
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TitleKeywords AS (
    SELECT mt.movie_id, 
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
),
CastDetails AS (
    SELECT c.movie_id, 
           COUNT(DISTINCT c.person_id) AS cast_count,
           STRING_AGG(CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_members
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),
MovieInfo AS (
    SELECT mt.movie_id,
           mt.title,
           mt.production_year,
           CASE 
               WHEN mt.production_year IS NULL THEN 'Unknown Year' 
               ELSE CAST(mt.production_year AS TEXT) 
           END AS production_year_str,
           COALESCE(tk.keywords, 'No Keywords') AS keywords,
           COALESCE(cd.cast_count, 0) AS cast_count,
           COALESCE(cd.cast_members, 'No Cast') AS cast_members
    FROM aka_title mt
    LEFT JOIN TitleKeywords tk ON mt.id = tk.movie_id
    LEFT JOIN CastDetails cd ON mt.id = cd.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mi.production_year_str,
    mi.keywords,
    mi.cast_count,
    mi.cast_members,
    ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank
FROM MovieHierarchy mh
JOIN MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE mi.cast_count > 0
ORDER BY mh.depth, mh.production_year DESC;

This SQL query performs several complex operations to retrieve a hierarchy of movies, along with their details. The query first builds a recursive CTE to gather movies produced on or before 2000, then aggregates keywords and cast details for each movie. It finally joins these results to display detailed information, ranking movies based on their production year within each depth level of the hierarchy.
