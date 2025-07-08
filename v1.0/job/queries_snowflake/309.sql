
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS total_cast,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopYearMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    mk.keywords,
    COUNT(DISTINCT co.name) AS company_count
FROM 
    TopYearMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
WHERE 
    mk.keywords IS NOT NULL OR tm.total_cast IS NULL
GROUP BY 
    tm.movie_title, tm.production_year, tm.total_cast, mk.keywords
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
