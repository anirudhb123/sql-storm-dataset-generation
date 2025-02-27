WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rnk
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rnk <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS all_actor_names,
    COALESCE(SUM(mk.keyword IS NOT NULL)::INTEGER, 0) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = cc.subject_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.title
GROUP BY 
    tm.title, tm.production_year
HAVING 
    keyword_count > 1
ORDER BY 
    tm.production_year DESC;
