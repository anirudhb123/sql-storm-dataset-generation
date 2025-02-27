WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL 
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_names,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = 2) AS num_reviews,
    COALESCE((SELECT 
                  STRING_AGG(DISTINCT kw.keyword, ', ') 
              FROM 
                  movie_keyword mk 
              JOIN 
                  keyword kw ON mk.keyword_id = kw.id 
              WHERE 
                  mk.movie_id = tm.movie_id), 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title;
