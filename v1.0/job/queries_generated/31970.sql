WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

RankedCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rn
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
),

ActorMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        rc.actor_name,
        COALESCE(mi.info, 'No Info Available') AS movie_info,
        rc.rn
    FROM MovieHierarchy mh
    LEFT JOIN RankedCast rc ON mh.movie_id = rc.movie_id
    LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
)

SELECT 
    ami.movie_id,
    ami.title,
    ami.production_year,
    STRING_AGG(ami.actor_name, ', ') AS actors,
    COUNT(DISTINCT ami.rn) AS num_roles,
    MAX(ami.movie_info) AS movie_summary
FROM ActorMovieInfo ami
GROUP BY ami.movie_id, ami.title, ami.production_year
HAVING COUNT(DISTINCT ami.rn) > 3
ORDER BY ami.production_year DESC, ami.title;

### Explanation:
1. **Recursive CTE** (`MovieHierarchy`): Generates a hierarchy of movies that aired from 2000 onwards, allowing us to capture movies and their episodes.
2. **Ranked Cast** (`RankedCast`): Uses window functions to rank actors based on their order in the cast list for each movie.
3. **Actor Movie Info** (`ActorMovieInfo`): Joins movie hierarchy with ranked cast and additional information about the movies using outer joins and COALESCE for handling NULLs.
4. The final SELECT aggregates actor names and filters the result to only include movies with more than three distinct roles, enabling performance benchmarking based on the demand for actor participation in movies. 
5. It uses `STRING_AGG` to concatenate actor names and sorts the results by year and title.

This provides a complex query that takes advantage of multiple advanced SQL features, ideal for performance benchmarking.
