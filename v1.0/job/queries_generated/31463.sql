WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level,
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        mh.level + 1,
        m.production_year,
        mh.movie_id
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
rated_movies AS (
    SELECT 
        m.id AS movie_id,
        COUNT(c.person_id) AS cast_count,
        AVG(info.rating) AS avg_rating,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_info info ON m.id = info.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        avg_rating,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY avg_rating DESC) AS year_rank
    FROM 
        rated_movies
)
SELECT 
    th.movie_id,
    th.title,
    th.production_year,
    th.cast_count,
    th.avg_rating,
    th.keywords,
    mh.level,
    mh.parent_movie_id
FROM 
    top_movies th
JOIN 
    movie_hierarchy mh ON th.movie_id = mh.movie_id
WHERE 
    th.year_rank <= 5
ORDER BY 
    th.production_year DESC, th.avg_rating DESC;
