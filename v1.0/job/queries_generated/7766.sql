WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        company_count,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)

SELECT 
    tm.title,
    tm.production_year,
    c.name AS company_name,
    k.keyword,
    i.info
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
ORDER BY 
    tm.production_year DESC, tm.title;
