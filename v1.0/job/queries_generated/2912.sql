WITH MovieStats AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) * 100 AS female_percentage,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000 AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        female_percentage,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        MovieStats
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.female_percentage,
    (SELECT AVG(actor_count) FROM TopMovies) AS average_actor_count,
    (SELECT COUNT(*) FROM TopMovies WHERE female_percentage > 50) AS movies_with_female_majority
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC;
