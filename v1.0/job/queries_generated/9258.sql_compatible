
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CAST(pc.info AS float)) AS avg_rating
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        (SELECT movie_id, AVG(CAST(info AS float)) AS info FROM movie_info GROUP BY movie_id) pc ON t.id = pc.movie_id
    WHERE 
        t.production_year >= 2000 AND 
        (it.info = 'rating' OR it.info = 'reviews')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_cast, 
        avg_rating,
        ROW_NUMBER() OVER (ORDER BY avg_rating DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.avg_rating
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.avg_rating DESC;
