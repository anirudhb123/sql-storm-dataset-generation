WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id
),
RecentMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5 -- Top 5 movies per year
        AND rm.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title) -- Last 5 years
),
StarActors AS (
    SELECT
        ak.name AS actor_name,
        COUNT(DISTINCT ca.movie_id) AS starred_movies
    FROM
        aka_name ak
    JOIN
        cast_info ca ON ak.person_id = ca.person_id
    GROUP BY
        ak.id
    HAVING
        COUNT(DISTINCT ca.movie_id) >= 3 -- Actors with at least 3 movies
),
KeywordUsage AS (
    SELECT
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id, k.keyword
    HAVING
        COUNT(*) > 1 -- More than one keyword per movie
),
FinalMetrics AS (
    SELECT
        r.title,
        r.production_year,
        r.cast_count,
        COALESCE(sa.actor_name, 'Unknown Actor') AS frequent_actor,
        COALESCE(SUM(ku.keyword_count), 0) AS total_keywords
    FROM
        RecentMovies r
    LEFT JOIN
        StarActors sa ON r.cast_count = (SELECT MAX(starred_movies) FROM StarActors)
    LEFT JOIN
        KeywordUsage ku ON r.movie_id = ku.movie_id
    GROUP BY
        r.title, r.production_year, sa.actor_name
)
SELECT
    title,
    production_year,
    cast_count,
    frequent_actor,
    total_keywords
FROM
    FinalMetrics
WHERE
    (cast_count > 5 OR total_keywords > 10)
ORDER BY
    production_year DESC, cast_count DESC, title
LIMIT 50;

This SQL query performs intricate operations using CTEs, including:

1. **RankedMovies**: Ranks movies by the number of unique actors and only considers the top 5 for the last 5 years.
2. **RecentMovies**: Isolates these top movies for further analysis.
3. **StarActors**: Identifies actors with at least 3 movies, capturing their contribution to overall filmography.
4. **KeywordUsage**: Aggregates movies with more than one keyword per title for insight into thematic elements.
5. **FinalMetrics**: Combines all the findings, ensuring NULL logic for potentially missing frequent actors, and aggregates keyword counts.

The outer query filters for movies with significant casts or keyword counts, ranking results for clearer insights in movie performance and outreach.
