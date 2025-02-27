WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(c.id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COALESCE(SUM(mi.info_id), 0) 
     FROM movie_info mi 
     WHERE mi.movie_id = tm.movie_id 
     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office,
    (SELECT COUNT(DISTINCT c.id) 
     FROM complete_cast cc 
     JOIN cast_info c ON cc.subject_id = c.person_id 
     WHERE cc.movie_id = tm.movie_id) AS unique_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.production_year > 2000
ORDER BY 
    tm.production_year DESC, 
    tm.title;
