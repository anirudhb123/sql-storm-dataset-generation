WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        actor_count, 
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)
SELECT 
    m.title,
    m.actor_count,
    m.keywords,
    COALESCE(p.info, 'No info available') AS additional_info
FROM 
    TopMovies m
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info p ON m.movie_id = p.person_id
WHERE 
    m.rank <= 10
ORDER BY 
    m.actor_count DESC, m.title;
