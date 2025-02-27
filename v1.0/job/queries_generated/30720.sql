WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title AS e
    JOIN 
        MovieHierarchy AS mh ON e.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(ci.person_id) > 5
),
RankingMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.total_cast,
        tm.production_year,
        COALESCE(si.avg_rating, 0) AS avg_rating
    FROM 
        TopMovies tm
    LEFT JOIN (
        SELECT 
            mi.movie_id,
            AVG(CAST(mi.info AS NUMERIC)) AS avg_rating
        FROM 
            movie_info mi
        INNER JOIN 
            info_type it ON mi.info_type_id = it.id
        WHERE 
            it.info = 'rating'
        GROUP BY 
            mi.movie_id
    ) si ON tm.movie_id = si.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.avg_rating,
    CASE 
        WHEN rm.avg_rating IS NULL THEN 'No Ratings'
        WHEN rm.avg_rating >= 8 THEN 'Highly Rated'
        WHEN rm.avg_rating >= 5 THEN 'Moderately Rated'
        ELSE 'Low Rating'
    END AS rating_category
FROM 
    RankingMovies rm
WHERE 
    rm.avg_rating IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
