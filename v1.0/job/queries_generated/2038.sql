WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
        JOIN cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywordCount AS (
    SELECT 
        m.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
        JOIN aka_title m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.actor_count, 
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN tm.actor_count > 10 THEN 'High'
        WHEN tm.actor_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS classification
FROM 
    TopMovies tm
    LEFT JOIN MovieKeywordCount mkc ON tm.title = mkc.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
