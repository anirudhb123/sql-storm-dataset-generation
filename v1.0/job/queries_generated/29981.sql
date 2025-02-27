WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        rt.role AS actor_role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS role_rank
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    WHERE
        t.production_year >= 2000   -- Filter for movies produced from the year 2000 onward
),

KeywordCount AS (
    SELECT
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        RankedMovies m ON mk.movie_id = m.movie_id
    GROUP BY
        m.movie_id
),

ComposedTitles AS (
    SELECT
        rm.movie_id,
        STRING_AGG(DISTINCT rm.title, ' | ') AS all_titles,
        STRING_AGG(DISTINCT rm.actor_name, ', ') AS actor_names,
        kc.keyword_count
    FROM
        RankedMovies rm
    JOIN
        KeywordCount kc ON rm.movie_id = kc.movie_id
    WHERE
        rm.role_rank <= 3  -- Get details for the top 3 actors in each movie
    GROUP BY
        rm.movie_id, kc.keyword_count
)

SELECT
    ct.movie_id,
    ct.all_titles,
    ct.actor_names,
    ct.keyword_count,
    CASE
        WHEN ct.keyword_count > 5 THEN 'Richly Tagged'
        WHEN ct.keyword_count BETWEEN 2 AND 5 THEN 'Moderately Tagged'
        ELSE 'Poorly Tagged'
    END AS tagging_quality
FROM
    ComposedTitles ct
ORDER BY
    ct.keyword_count DESC, ct.movie_id;

This SQL query consists of several Common Table Expressions (CTEs) to craft a comprehensive report on movies, including their titles, leading actors, keyword counts, and an evaluation of their tagging quality. The use of `STRING_AGG` allows for the aggregation of multiple actors and titles into single fields for easier readability.
