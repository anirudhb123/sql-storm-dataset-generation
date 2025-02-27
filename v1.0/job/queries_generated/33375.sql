WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        ak.production_year >= 2000
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(c.person_id) > 2
),
HighestRanked AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count
    FROM 
        TopMovies tm
    WHERE 
        tm.rank <= 5
)
SELECT 
    hd.movie_id,
    hd.title,
    hd.production_year,
    hd.cast_count,
    COALESCE(ki.keyword, 'No Keywords') AS keyword,
    mp.note AS production_note
FROM 
    HighestRanked hd
LEFT JOIN 
    movie_keyword mk ON hd.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mp ON hd.movie_id = mp.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Production Note')
ORDER BY 
    hd.production_year DESC, hd.cast_count DESC;

This query achieves several things:
- It uses a recursive Common Table Expression (CTE) to create a hierarchy of movies starting from those produced after 2000.
- It calculates the cast count for each movie and ranks them within their production year.
- It filters for movies that have a cast count greater than 2.
- It joins to get keywords and production notes for the top 5 movies per year.
- It employs handling for NULL values by using `COALESCE` to provide a default string when no keywords are found.
