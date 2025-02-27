WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT g.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword g ON mk.keyword_id = g.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        mg.genres,
        COALESCE(ca.rn, 'No Cast') AS cast_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        (SELECT 
            ci.movie_id, 
            AVG(RANK) AS rn
         FROM 
            (SELECT 
                movie_id, 
                RANK() OVER (PARTITION BY movie_id ORDER BY ci.nr_order) AS RANK
            FROM 
                cast_info ci) AS ci
         GROUP BY 
            ci.movie_id) ca ON rm.title = ca.movie_id
    LEFT JOIN 
        MovieGenres mg ON rm.title = mg.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    tm.genres AS Genre_List,
    tm.cast_rank AS Average_Cast_Ranking
FROM 
    TopMovies tm
WHERE 
    NOT EXISTS (SELECT 1 
                 FROM movie_info mi 
                 WHERE mi.movie_id = tm.movie_id 
                   AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office'))
ORDER BY 
    tm.production_year DESC, 
    tm.title;
