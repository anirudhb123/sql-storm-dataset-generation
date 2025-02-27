WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        a.id, a.title, a.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
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
        pk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularKeywords pk ON rm.title = (SELECT title FROM aka_title WHERE id = rm.title LIMIT 1)
    WHERE 
        rm.rn <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(tm.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN tm.cast_count > 10 THEN 'High'
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS popularity
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
