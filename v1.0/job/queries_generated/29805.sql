WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        k.keyword,
        COUNT(ci.actor_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.actor_id) DESC) AS year_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year, k.keyword
),
TopKeywords AS (
    SELECT 
        keyword,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS keyword_rank
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    SUM(CASE WHEN si.status = 'Released' THEN 1 ELSE 0 END) AS released_movies,
    AVG(t.production_year) AS avg_production_year
FROM 
    TopKeywords mk
JOIN 
    movie_keyword mk2 ON mk.keyword = mk2.keyword
JOIN 
    title t ON mk2.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    (SELECT movie_id, 'Released' AS status FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Status') AND info = 'Released') si ON t.id = si.movie_id
GROUP BY 
    mk.keyword
ORDER BY 
    movie_count DESC
LIMIT 10;
