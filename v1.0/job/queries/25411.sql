WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    tm.keywords,
    ci.role_id,
    rt.role
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    role_type rt ON ci.person_role_id = rt.id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;