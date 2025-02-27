WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all titles as the root of recursion
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM
        title t
    WHERE
        t.production_year >= 2000 -- Filter for more recent movies
  
    UNION ALL
  
    -- Recursive case: Join movie links to get related movies
    SELECT
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level
    FROM
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedMovieData AS (
    -- Aggregate data for each movie including its primary info and keywords
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
),
TopMovies AS (
    -- Identifying the top 10 movies with the highest number of keywords and actors
    SELECT
        amd.movie_id,
        amd.title,
        amd.production_year,
        amd.keyword_count,
        amd.cast_count,
        ROW_NUMBER() OVER (ORDER BY amd.keyword_count DESC, amd.cast_count DESC) AS rank
    FROM
        AggregatedMovieData amd
    WHERE
        amd.keyword_count > 0 -- Exclude movies without keywords
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    COALESCE(p.firstname || ' ' || p.lastname, 'Unknown') AS main_actor,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Blockbuster'
        ELSE 'Indie'
    END AS classification
FROM 
    TopMovies tm
LEFT JOIN 
    (SELECT 
        ci.movie_id,
        ak.name AS firstname,
        ak.surname AS lastname
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ci.nr_order = 1 -- Get the main actor for each movie
    ) p ON tm.movie_id = p.movie_id
WHERE
    tm.rank <= 10 -- Limit to top 10 movies
ORDER BY
    tm.rank;
