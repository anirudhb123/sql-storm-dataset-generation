
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM 
        TopRankedMovies m
    LEFT JOIN 
        movie_info mi ON m.title = mi.info
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mi.movie_info, 'No Info Available') AS movie_info,
    (SELECT COUNT(DISTINCT c.person_id) 
     FROM complete_cast cc 
     JOIN cast_info c ON cc.subject_id = c.id 
     WHERE cc.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)) AS total_cast,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1) AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword = 'Award')) 
        THEN 'Award-winning' 
        ELSE 'Non-Award-winning' 
    END AS award_status
FROM 
    TopRankedMovies tm
LEFT JOIN 
    MovieInfo mi ON tm.title = mi.title AND tm.production_year = mi.production_year
ORDER BY 
    tm.production_year DESC, 
    tm.title;
