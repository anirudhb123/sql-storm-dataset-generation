
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Episode: ', m.title) AS title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title AS m
    JOIN 
        MovieHierarchy AS mh ON m.episode_of_id = mh.movie_id
),

PopularMovies AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info AS c
    JOIN 
        aka_title AS a ON c.movie_id = a.movie_id
    GROUP BY 
        c.movie_id
    HAVING 
        COUNT(c.person_id) >= 5
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(pm.cast_count, 0) AS cast_count,
    mk.keywords
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    PopularMovies AS pm ON mh.movie_id = pm.movie_id
LEFT JOIN 
    MovieKeywords AS mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level = 1
ORDER BY 
    mh.production_year DESC, mh.title ASC;
