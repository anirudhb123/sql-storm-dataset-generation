
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS full_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        t.id, t.title, t.production_year
),

HighCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.full_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)

SELECT 
    hm.movie_id,
    hm.title,
    hm.production_year,
    hm.cast_count,
    hm.full_cast,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = hm.movie_id) AS info_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = hm.movie_id) AS keywords
FROM 
    HighCastMovies hm
ORDER BY 
    hm.production_year DESC, hm.cast_count DESC;
