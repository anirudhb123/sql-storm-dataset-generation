WITH RankedMovies AS (
    SELECT 
        a.title, 
        COUNT(c.person_id) AS cast_count,
        AVG(mi.info::numeric) AS avg_budget,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rnk
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        cast_count,
        avg_budget
    FROM 
        RankedMovies
    WHERE 
        rnk <= 5
)
SELECT 
    tm.title,
    tm.cast_count,
    tm.avg_budget,
    COALESCE(k.keyword, 'No keyword') AS keyword
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    tm.avg_budget DESC;
