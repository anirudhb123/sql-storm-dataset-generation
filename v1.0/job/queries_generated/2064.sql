WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
RelatedTitles AS (
    SELECT 
        mt.title AS related_title,
        mt.production_year,
        COUNT(ml.linked_movie_id) AS link_count
    FROM 
        movie_link ml
    INNER JOIN 
        title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year IN (SELECT production_year FROM TopMovies)
    GROUP BY 
        mt.title, mt.production_year
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(rt.link_count, 0) AS related_link_count
FROM 
    TopMovies tm
LEFT JOIN 
    RelatedTitles rt ON tm.production_year = rt.production_year
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
