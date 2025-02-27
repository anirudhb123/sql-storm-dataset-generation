WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.actor_count
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = m.id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    mk.keyword,
    COUNT(mk.title) AS movie_count,
    AVG(tm.actor_count) AS average_actor_count
FROM 
    MovieKeywords mk
JOIN 
    TopMovies tm ON mk.title = tm.title
GROUP BY 
    mk.keyword
HAVING 
    COUNT(mk.title) >= 2
ORDER BY 
    movie_count DESC, average_actor_count DESC;
