
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        title mt ON at.movie_id = mt.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
),

MovieGenres AS (
    SELECT 
        at.movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS genres
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        at.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mg.genres,
    COALESCE((SELECT MAX(mh.info) 
              FROM movie_info mh 
              WHERE mh.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1) AND mh.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')), 
              'No Rating') AS highest_rating,
    COUNT(DISTINCT ci.id) FILTER (WHERE ci.person_role_id IS NOT NULL) AS distinct_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)
LEFT JOIN 
    MovieGenres mg ON mg.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)
LEFT JOIN 
    cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id LIMIT 1)
WHERE 
    rm.year_rank <= 5
GROUP BY 
    rm.title, rm.production_year, rm.cast_count, mg.genres
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
