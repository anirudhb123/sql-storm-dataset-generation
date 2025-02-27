WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
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
        rm.rn = 1
    ORDER BY 
        rm.cast_count DESC
    LIMIT 10
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    m.actors,
    m.keywords
FROM 
    TopMovies m
JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
WHERE 
    mi.info LIKE '%blockbuster%'
ORDER BY 
    m.production_year ASC;
