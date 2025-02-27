WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS level
    FROM cast_info ci
    WHERE ci.person_role_id IN (
        SELECT id FROM role_type WHERE role = 'actor'
    )
    UNION ALL
    SELECT ci.person_id, ci.movie_id, ah.level + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id <> ah.person_id
),
MovieInfo AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT ca.person_id) AS actor_count,
        string_agg(DISTINCT ak.name, ', ') AS actor_names
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        actor_count,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, production_year ASC) AS rank
    FROM MovieInfo
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    CASE 
        WHEN tc.kind IS NULL THEN 'Unknown'
        ELSE tc.kind
    END AS movie_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM TopMovies tm
LEFT JOIN movie_keyword mk ON tm.title = (
        SELECT title FROM title t WHERE t.id = mk.movie_id
    )
LEFT JOIN kind_type tc ON (
    SELECT kt.kind FROM aka_title mt 
    JOIN kind_type kt ON mt.kind_id = kt.id 
    WHERE mt.title = tm.title
) IS NOT NULL
WHERE tm.rank <= 10
GROUP BY tm.title, tm.production_year, tm.actor_count, tm.actor_names, tc.kind
ORDER BY tm.actor_count DESC;
