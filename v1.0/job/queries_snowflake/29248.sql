
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS main_cast,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        main_cast,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5  
)
SELECT 
    tm.production_year,
    COUNT(tm.movie_id) AS total_movies,
    LISTAGG(tm.title, '; ') WITHIN GROUP (ORDER BY tm.title) AS top_movies,
    LISTAGG(tm.main_cast, '; ') WITHIN GROUP (ORDER BY tm.main_cast) AS main_cast_list,
    LISTAGG(tm.keywords, '; ') WITHIN GROUP (ORDER BY tm.keywords) AS all_keywords
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year;
