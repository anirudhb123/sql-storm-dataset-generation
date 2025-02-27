WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        t.kind AS genre,
        COALESCE(count(ci.id), 0) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, t.kind
    HAVING 
        m.production_year >= 2000 AND
        COALESCE(count(ci.id), 0) > 5

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.genre,
        mh.cast_count
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        ml.linked_movie_id IS NOT NULL
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.genre,
        mh.cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.genre ORDER BY mh.cast_count DESC) AS genre_rank
    FROM 
        MovieHierarchy mh
)

SELECT 
    tm.title AS movie_title,
    tm.production_year,
    COALESCE((SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id), 0) AS keyword_count,
    REPLACE(mh.genre, ' ', '_') AS genre_label,
    CASE 
        WHEN tm.cast_count IS NULL THEN 'No Cast'
        ELSE CAST(tm.cast_count AS TEXT)
    END AS cast_count_text,
    CASE 
        WHEN tm.genre IS NULL THEN 'Unknown Genre'
        WHEN tm.genre IN ('Horror', 'Thriller') THEN 'Chills Guaranteed!'
        ELSE 'Enjoy the Show!'
    END AS viewing_advice
FROM 
    TopMovies tm
LEFT JOIN 
    stand_in_movies_directory s ON tm.movie_id = s.movie_id AND s.currently_screening = TRUE
WHERE 
    tm.genre_rank <= 3
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC NULLS LAST
LIMIT 20;

