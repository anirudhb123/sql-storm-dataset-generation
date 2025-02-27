WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS num_cast,
        AVG(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS avg_roles,
        ROW_NUMBER() OVER (ORDER BY a.production_year DESC, a.title) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id
),
HighCastMovies AS (
    SELECT 
        movie_title, 
        num_cast
    FROM 
        RankedMovies
    WHERE 
        num_cast > 10
)
SELECT 
    h.movie_title,
    h.num_cast,
    COALESCE(m.info, 'No Information Available') AS movie_info,
    (SELECT GROUP_CONCAT(k.keyword SEPARATOR ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = a.id) AS keywords
FROM 
    HighCastMovies h
LEFT JOIN 
    movie_info m ON h.movie_title = m.info
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
ORDER BY 
    h.num_cast DESC
LIMIT 5;
