
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.id = c.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieGenres AS (
    SELECT 
        at.id AS movie_id,
        COALESCE(LISTAGG(DISTINCT kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword), 'No Genres') AS genres
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        at.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    mg.genres,
    COALESCE(SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS award_count,
    MAX(ml.linked_movie_id) AS related_movie_id
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id) 
LEFT JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
LEFT JOIN 
    MovieGenres mg ON tm.title = (SELECT title FROM aka_title WHERE id = mg.movie_id)
LEFT JOIN 
    movie_link ml ON tm.production_year = (
        SELECT production_year FROM aka_title WHERE id = ml.movie_id
    )
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, mg.genres
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
