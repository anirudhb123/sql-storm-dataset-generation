
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COUNT(c.movie_id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast b ON a.id = b.movie_id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cn.name, 'Unknown') AS company_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    tm.production_year IS NOT NULL
GROUP BY 
    tm.title, 
    tm.production_year, 
    cn.name
ORDER BY 
    tm.production_year DESC, 
    tm.title;
