WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select all movies that have no episode_of_id.
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    WHERE
        t.episode_of_id IS NULL

    UNION ALL
    
    -- Recursive case: Select episodes and join with the previous level
    SELECT
        t.id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        aka_title t
    INNER JOIN
        movie_hierarchy mh ON t.episode_of_id = mh.movie_id
),

-- Calculate the average ratings for movies along with their info and related companies
avg_movie_ratings AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        AVG(COALESCE(mi.info::FLOAT, 0)) AS avg_rating
    FROM
        movie_info mi
    JOIN
        aka_title m ON mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        m.movie_id, m.title, m.production_year
),

-- Get the names of the cast members for our movies
cast_details AS (
    SELECT
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
)

-- Final query that combines all the information
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(avg.avg_rating, 0) AS avg_rating,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    mh.level
FROM
    movie_hierarchy mh
LEFT JOIN
    avg_movie_ratings avg ON mh.movie_id = avg.movie_id
LEFT JOIN
    cast_details cd ON mh.movie_id = cd.movie_id
ORDER BY
    mh.production_year DESC, mh.title;
