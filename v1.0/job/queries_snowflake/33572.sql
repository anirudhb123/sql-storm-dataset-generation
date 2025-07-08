WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        m.production_year
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
        
    UNION ALL

    SELECT 
        mc.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mh.level + 1,
        mt.production_year
    FROM 
        movie_link mc
    JOIN 
        title mt ON mc.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS actors_with_notes,
        AVG(COALESCE(CAST(mg.info AS FLOAT), 0)) AS average_movie_rating
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_info mg ON mh.movie_id = mg.movie_id 
    WHERE 
        mg.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
),
TopMovies AS (
    SELECT 
        ms.*,
        RANK() OVER (ORDER BY ms.average_movie_rating DESC) AS rank
    FROM 
        MovieStats ms
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_actors,
    tm.actors_with_notes,
    tm.average_movie_rating
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.average_movie_rating DESC, tm.total_actors DESC;
