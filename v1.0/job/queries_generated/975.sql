WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        AVG(mr.rating) OVER (PARTITION BY t.id) AS average_rating,
        ROW_NUMBER() OVER (ORDER BY AVG(mr.rating) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_rating mr ON t.id = mr.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
        AND mi.info IS NOT NULL
),
Genres AS (
    SELECT 
        movie_id,
        STRING_AGG(info, ', ') AS genre_list
    FROM 
        movie_info 
    WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    GROUP BY 
        movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.average_rating,
    g.genre_list
FROM 
    RankedMovies rm
LEFT JOIN 
    Genres g ON rm.id = g.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.average_rating DESC, 
    rm.actor_count DESC;
