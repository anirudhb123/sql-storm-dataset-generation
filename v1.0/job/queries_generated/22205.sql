WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
),
MoviesWith info AS (
    SELECT 
        r.movie_title,
        r.production_year,
        COALESCE(SUM(m.keyword_id), 0) AS keyword_count,
        COALESCE(STRING_AGG(k.keyword, ', '), 'No keywords') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_keyword m ON r.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        r.movie_title, r.production_year
)

SELECT 
    mw.movie_title,
    mw.production_year,
    mw.keyword_count,
    mw.keywords,
    COALESCE(a.actor_count, 0) AS actor_count,
    COALESCE(a.actor_names, 'No actors') AS actor_names
FROM 
    MoviesWithInfo mw
LEFT JOIN (
    SELECT 
        a.movie_id,
        COUNT(*) AS actor_count,
        STRING_AGG(a.actor_name, ', ') AS actor_names
    FROM 
        ActorsInMovies a
    GROUP BY 
        a.movie_id
) a ON mw.movie_id = a.movie_id
WHERE 
    mw.keyword_count > (
        SELECT AVG(keyword_count) 
        FROM (
            SELECT 
                COUNT(m.keyword_id) AS keyword_count
            FROM 
                movie_keyword m
            GROUP BY 
                m.movie_id
        ) AS avg_keywords
    )
ORDER BY 
    mw.production_year DESC, mw.keyword_count DESC, mw.movie_title;


### Explanation of Query Components:
1. **Common Table Expressions (CTEs)**:
    - **RankedMovies**: This CTE ranks movies by year and title, aggregating total records to discern the distribution yearly.
    - **ActorsInMovies**: This CTE identifies actors associated with each movie, ordering them by name and providing a numeric rank within the movie's cast.
    - **MoviesWithInfo**: Builds a snapshot dataset of movies including keyword counts and concatenated keywords while ensuring movie relationships are properly represented.

2. **Outer Joins**: The query utilizes LEFT JOINs, particularly in the main SELECT, allowing the results to include movies without associated actors or keywords.

3. **Aggregations**:
    - The use of `COUNT` and `SUM` to quantify actors per movie and keyword categories.
    - `STRING_AGG` is demonstrated to create a comma-separated list of keywords and actor names.

4. **Correlated Subquery**: The filtering clause in the main SELECT uses a correlated subquery to find movies being above the average keyword usage threshold.

5. **Complicated predicates**: CALCULATE predicates based on external calculations (like average keyword count) for returning rich and filtered datasets.

6. **NULL handling**: The `COALESCE` function ensures the results handle cases where there are no actors or keywords gracefully instead of returning NULL.

This query aims to be complex with rich data expressions suitable for deeper analysis and performance benchmarking of SQL operations over potentially large datasets.
