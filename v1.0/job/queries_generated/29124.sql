WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
        LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
        LEFT JOIN cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, k.keyword
),
HighRatedMovies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        m.kind_id,
        m.movie_keyword,
        m.cast_count
    FROM 
        RankedMovies m
    JOIN movie_info mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        AND mi.info::float >= 8.0
),
ActorsWithMoreThanTwoMovies AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        cast_info c
        JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id, a.name
    HAVING 
        COUNT(c.movie_id) > 2
)
SELECT 
    h.movie_title,
    h.production_year,
    h.movie_keyword,
    STRING_AGG(DISTINCT a.actor_name, ', ') AS actors
FROM 
    HighRatedMovies h
LEFT JOIN 
    cast_info c ON h.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    a.person_id IN (SELECT person_id FROM ActorsWithMoreThanTwoMovies)
GROUP BY 
    h.movie_title, h.production_year, h.movie_keyword
ORDER BY 
    h.production_year DESC, h.movie_title;
