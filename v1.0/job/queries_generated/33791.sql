WITH RECURSIVE MovieHierarchy AS (
    -- CTE to establish the hierarchy of movies and episodes
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        0 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.episode_of_id,
        mh.level + 1
    FROM 
        title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
StarCast AS (
    -- CTE to aggregate cast information for movies/episodes
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    -- CTE to fetch keywords associated with movies
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(sc.cast_count, 0) AS total_cast,
    COALESCE(mk.keywords, 'No Keywords') AS associated_keywords,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COALESCE(sc.cast_count,0) DESC) AS rank_by_cast_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    StarCast sc ON mh.movie_id = sc.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND mh.level = 0
ORDER BY 
    mh.production_year DESC,
    rank_by_cast_count ASC

This SQL query combines multiple advanced SQL constructs for performance benchmarking:

1. A Recursive Common Table Expression (CTE) named `MovieHierarchy` constructs a hierarchy of movies and their episodes.
2. Another CTE, `StarCast`, calculates the total number of distinct cast members for each movie.
3. A third CTE, `MovieKeywords`, aggregates relevant keywords associated with each movie.
4. The main SELECT statement retrieves movie titles, production years, total cast counts, and associated keywords while applying COALESCE to handle NULL values.
5. A window function computes the rank of each movie within its production year by the total cast count.
6. The query filters for movies produced in the year 2000 or later and orders them by production year and rank.
7. String aggregations and NULL logic are implemented effectively, making the query complex and performance-oriented for benchmarking scenarios.
