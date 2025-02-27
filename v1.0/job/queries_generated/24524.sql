WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        COALESCE(mt.season_nr, 0) AS season_number,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(at.episode_nr, 0) AS episode_number,
        COALESCE(at.season_nr, 0) AS season_number,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    COUNT(DISTINCT CASE WHEN mt.production_year = 2023 THEN c.movie_id END) AS movies_in_2023,
    STRING_AGG(DISTINCT LOWER(aka.title), ', ') FILTER (WHERE aka.title IS NOT NULL) AS aggregated_titles,
    AVG(mh.depth) AS avg_depth,
    MAX(mh.episode_number) AS max_episode_numbers,
    MIN(mh.season_number) AS min_season_numbers
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
INNER JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title aka ON mh.movie_id = aka.id
LEFT JOIN 
    movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
WHERE 
    a.name IS NOT NULL 
    AND (c.note IS NULL OR c.note NOT LIKE '%extra%')
    AND EXISTS (SELECT 1 FROM info_type it WHERE it.info = 'Cast') 
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;

### Explanation:
- The query constructs a recursive CTE (`MovieHierarchy`) to derive a hierarchy of movies, taking into consideration linked movies, which allows fetching both original and associated movies.
- It aggregates actor information along with movie data, filtering on non-null values, validating with `EXISTS`, and checking correlation to a certain production year.
- It uses `STRING_AGG` for concatenating titles from `aka_title` while applying a case-insensitive transformation with `LOWER`.
- The HAVING clause filters actors based on a condition, showing only those with more than 5 movie appearances.
- Finally, the result is sorted by the total number of movies in descending order and limited to the top 10 actors.
