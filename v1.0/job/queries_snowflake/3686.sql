
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > 10 THEN 'High'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS popularity
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.popularity,
    COALESCE(pk.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    PopularKeywords pk ON tm.title = (SELECT title FROM aka_title WHERE id = pk.movie_id)
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
