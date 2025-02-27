WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        num_cast_members
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
KeywordCount AS (
    SELECT 
        m.movie_id, 
        COUNT(k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN tm.num_cast_members >= 10 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_type
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCount kc ON tm.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
ORDER BY 
    tm.production_year DESC, 
    keyword_count DESC;
