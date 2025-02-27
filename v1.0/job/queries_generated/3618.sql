WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY YEAR(m.production_year) ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(a.name, 'Unknown') AS lead_actor
    FROM 
        RankedMovies rm
    LEFT JOIN 
        (SELECT 
            c.movie_id, 
            a.name 
        FROM 
            cast_info c
        JOIN 
            aka_name a ON c.person_id = a.person_id
        WHERE 
            c.nr_order = 1) a ON rm.movie_id = a.movie_id
    WHERE 
        rm.rank_by_cast_count <= 5
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.lead_actor,
    COUNT(mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.lead_actor
ORDER BY 
    tm.production_year DESC, keyword_count DESC
LIMIT 10;
