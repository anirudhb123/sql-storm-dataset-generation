WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mc.linked_movie_id,
        ma.title AS movie_title,
        ma.production_year,
        level + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title ma ON mc.linked_movie_id = ma.id
    JOIN 
        MovieCTE m ON mc.movie_id = m.movie_id
), 
ActorInfo AS (
    SELECT 
        a.person_id,
        a.movie_id,
        ak.name,
        ak.md5sum,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY a.nr_order) AS actor_rank
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        cte.movie_id,
        cte.movie_title,
        cte.production_year,
        COUNT(DISTINCT ai.person_id) AS actor_count,
        COALESCE(ks.keyword_count, 0) AS keyword_count
    FROM 
        MovieCTE cte
    LEFT JOIN 
        ActorInfo ai ON cte.movie_id = ai.movie_id
    LEFT JOIN 
        KeywordStats ks ON cte.movie_id = ks.movie_id
    WHERE 
        cte.level <= 3  -- Limit the recursion depth
    GROUP BY 
        cte.movie_id, cte.movie_title, cte.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year,
        actor_count,
        keyword_count,
        DENSE_RANK() OVER (ORDER BY actor_count DESC, keyword_count DESC) AS rank
    FROM 
        FilteredMovies
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.keyword_count,
    tm.rank
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10  -- Get the top 10 movies
ORDER BY 
    tm.actor_count DESC, 
    tm.keyword_count DESC;

This complex SQL query accomplishes several tasks:
1. Defines a recursive CTE to fetch movies and their linked movies up to a certain level, representing relationships.
2. Aggregates actor information using a window function to rank actors per movie.
3. Computes keyword statistics for movies in a separate CTE.
4. Combines the results to filter out and rank movies based on actor count and keyword popularity.
5. Returns a final selection of the top movies based on these criteria.
