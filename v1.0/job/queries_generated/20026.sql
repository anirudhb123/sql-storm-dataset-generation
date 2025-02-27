WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    WHERE
        t.production_year IS NOT NULL
    AND
        t.title IS NOT NULL
),
CastSummary AS (
    SELECT
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT a.id) AS unique_actors
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
MoviesWithDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.cast_names,
        cs.unique_actors,
        CASE WHEN cs.unique_actors > 10 THEN 'Ensemble' ELSE 'Small Cast' END AS cast_size
    FROM
        RankedMovies rm
    LEFT JOIN
        CastSummary cs ON rm.movie_id = cs.movie_id
)
SELECT
    m.title,
    m.production_year,
    m.cast_names,
    m.unique_actors,
    m.cast_size,
    CASE 
        WHEN m.cast_size = 'Ensemble' THEN 'This movie features a large ensemble cast!'
        ELSE 'This movie features a smaller cast.'
    END AS cast_description
FROM
    MoviesWithDetails m
WHERE
    m.production_year >= 2000
ORDER BY
    m.production_year DESC,
    m.unique_actors DESC
LIMIT 100;

-- Subquery to find movies with similar titles
WITH TitleSimilarities AS (
    SELECT
        m1.title AS title1,
        m1.movie_id AS movie1_id,
        m2.title AS title2,
        m2.movie_id AS movie2_id,
        LENGTH(m1.title) - LENGTH(REPLACE(m1.title, ' ', '')) AS space_count1,
        LENGTH(m2.title) - LENGTH(REPLACE(m2.title, ' ', '')) AS space_count2
    FROM
        aka_title m1
    JOIN
        aka_title m2 ON m1.id <> m2.id
    WHERE
        LOWER(m1.title) LIKE LOWER(CONCAT('%', SUBSTRING(m2.title, 1, 3), '%'))
),
SampleQueries AS (
    SELECT 
        title1, 
        title2, 
        space_count1 + space_count2 AS combined_space_count
    FROM 
        TitleSimilarities
    WHERE 
        combined_space_count > 3
)
SELECT * FROM SampleQueries
ORDER BY combined_space_count DESC
LIMIT 50;

-- Final Output of Movies
SELECT 
    DISTINCT m.title, 
    m.production_year, 
    COALESCE(m.cast_names, 'Unknown') AS cast_names,
    m.cast_size,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    MoviesWithDetails m
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.title, m.production_year, m.cast_names, m.cast_size
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    m.production_year DESC, keyword_count DESC;
