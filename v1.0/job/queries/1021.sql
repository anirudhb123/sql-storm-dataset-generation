
WITH MovieStatistics AS (
    SELECT 
        a.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        AVG(CAST(mi.info AS FLOAT)) AS avg_rating,
        RANK() OVER (ORDER BY AVG(CAST(mi.info AS FLOAT)) DESC) AS movie_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN 
        movie_info mi ON a.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') 
    GROUP BY 
        a.movie_id
    HAVING 
        COUNT(DISTINCT c.person_id) > 10
), TopMovies AS (
    SELECT 
        m.movie_id, 
        a.title,
        m.num_cast_members,
        m.avg_rating,
        m.movie_rank
    FROM 
        MovieStatistics m
    JOIN 
        aka_title a ON m.movie_id = a.movie_id
    WHERE 
        m.movie_rank <= 10
)
SELECT 
    t.title,
    COALESCE(c1.name, 'Unknown') AS director_name,
    t.avg_rating,
    t.num_cast_members,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies t
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    AKA_name c1 ON ci.movie_id = c1.person_id AND ci.role_id = (SELECT id FROM role_type WHERE role = 'Director')
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    t.title, c1.name, t.avg_rating, t.num_cast_members
HAVING 
    t.avg_rating IS NOT NULL AND t.num_cast_members > 0
ORDER BY 
    t.avg_rating DESC, t.title;
