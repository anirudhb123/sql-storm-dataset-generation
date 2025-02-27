WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    r.rank,
    r.title,
    r.production_year,
    r.cast_count,
    k.keyword_count,
    r.actor_names
FROM 
    RankedMovies r
JOIN 
    KeywordedMovies k ON r.movie_id = k.movie_id
WHERE 
    r.cast_count > 0
ORDER BY 
    r.rank
LIMIT 10;
