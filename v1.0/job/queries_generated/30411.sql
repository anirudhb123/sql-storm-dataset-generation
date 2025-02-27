WITH RECURSIVE MovieHierarchy AS (
    -- Recursive CTE to generate a hierarchy of movies linked by episodes
    SELECT 
        t.id AS movie_id,
        t.title,
        t.season_nr,
        t.episode_nr,
        1 AS depth
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.season_nr,
        e.episode_nr,
        mh.depth + 1
    FROM 
        title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
MovieInfo AS (
    -- CTE for movie info and associated keywords
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        ci.image_caption,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id 
    LEFT JOIN 
        (SELECT movie_id, info AS image_caption FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Image')) ci ON m.id = ci.movie_id
),
TopMovies AS (
    -- CTE for filtering the top movies with at least 3 distinct keywords
    SELECT 
        movie_id, 
        title, 
        COUNT(DISTINCT keyword) AS unique_keyword_count
    FROM 
        MovieInfo
    GROUP BY 
        movie_id, title
    HAVING 
        COUNT(DISTINCT keyword) >= 3
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.season_nr,
    mh.episode_nr,
    mi.unique_keyword_count,
    mi.image_caption,
    ci.country_code,
    COUNT(DISTINCT co.id) AS company_count,
    SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_associated
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopMovies mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.season_nr, mh.episode_nr, mi.unique_keyword_count, mi.image_caption, ci.country_code
ORDER BY 
    unique_keyword_count DESC,
    mh.title
LIMIT 100;
