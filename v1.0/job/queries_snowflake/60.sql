
WITH MovieStats AS (
    SELECT 
        a.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CAST(mi.info AS numeric)) AS average_rating,
        SUM(CASE 
                WHEN mi.note IS NOT NULL THEN 1 
                ELSE 0 
            END) AS rated_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        a.title
),
TopMovies AS (
    SELECT 
        m.title,
        m.actor_count,
        m.average_rating,
        m.rated_count,
        RANK() OVER (ORDER BY m.average_rating DESC) AS rank
    FROM 
        MovieStats m
)
SELECT 
    m.title,
    m.actor_count,
    m.average_rating,
    m.rated_count,
    k.keyword AS genre
FROM 
    TopMovies m
LEFT JOIN 
    movie_keyword mk ON m.title = (SELECT a.title FROM aka_title a WHERE a.id = mk.movie_id LIMIT 1)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.rank <= 10
ORDER BY 
    m.average_rating DESC 
NULLS LAST;
