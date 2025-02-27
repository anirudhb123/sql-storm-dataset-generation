WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS level
    FROM cast_info ci
    WHERE ci.person_id IS NOT NULL

    UNION ALL

    SELECT ci.person_id, ci.movie_id, ah.level + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id IS NOT NULL AND ah.level < 5 -- Limit recursion depth to prevent infinite loops
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
TopMovies AS (
    SELECT
        a.title,
        COUNT(DISTINCT c.person_id) AS num_actors,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title a
    JOIN cast_info c ON a.movie_id = c.movie_id
    WHERE a.production_year BETWEEN 2000 AND 2023
    GROUP BY a.title
    HAVING COUNT(DISTINCT c.person_id) > 5
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT
    tm.title,
    tm.num_actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.companies, '{}') AS companies,
    ah.level AS actor_hierarchy_level
FROM TopMovies tm
LEFT JOIN MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN MovieCompanies mc ON tm.movie_id = mc.movie_id
LEFT JOIN ActorHierarchy ah ON tm.num_actors = ah.level
WHERE tm.rank <= 10
ORDER BY tm.num_actors DESC, tm.title;
