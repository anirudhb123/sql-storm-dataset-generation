WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year AS year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS akas,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.year,
        rm.cast_count,
        rm.akas,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)

SELECT 
    tm.title,
    tm.year,
    tm.cast_count,
    tm.akas,
    tm.keywords,
    COALESCE(ci.note, 'No additional info') AS cast_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    info_type it ON cc.status_id = it.id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
LEFT JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id
ORDER BY 
    tm.cast_count DESC;
