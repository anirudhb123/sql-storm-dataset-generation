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