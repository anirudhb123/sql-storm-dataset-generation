WITH RECURSIVE CastHierarchy AS (
    SELECT
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        1 AS depth,
        ARRAY[ci.id] AS path
    FROM cast_info ci
    WHERE ci.note IS NOT NULL

    UNION ALL

    SELECT
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        ch.depth + 1,
        path || ci.id
    FROM cast_info ci
    JOIN CastHierarchy ch ON ci.movie_id = ch.movie_id AND ci.id <> ANY(ch.path)
),
MovieStats AS (
    SELECT
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS rating,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS budget
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN movie_info mi ON mt.movie_id = mi.movie_id
    WHERE mt.production_year BETWEEN 2000 AND 2023
    GROUP BY mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank_by_actors
    FROM MovieStats
    WHERE actor_count > 0
)

SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.keyword_count,
    CASE 
        WHEN tm.keyword_count > 10 THEN 'High'
        WHEN tm.keyword_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_category,
    COALESCE(AVG(CASE WHEN ch.depth IS NOT NULL THEN ch.depth END), 0) AS avg_cast_depth
FROM TopMovies tm
LEFT JOIN CastHierarchy ch ON tm.title IN (SELECT title FROM aka_title WHERE movie_id = ch.movie_id)
WHERE tm.rank_by_actors <= 5
GROUP BY tm.title, tm.production_year, tm.actor_count, tm.keyword_count
ORDER BY tm.production_year DESC, tm.actor_count DESC;
