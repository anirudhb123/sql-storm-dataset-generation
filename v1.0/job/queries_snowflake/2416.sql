
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMoviesByYear AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT c.person_id) AS total_casts,
    MAX(p.info) AS production_info
FROM 
    TopMoviesByYear t
LEFT JOIN 
    MovieKeywords mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id AND it.id = p.info_type_id
WHERE 
    p.info IS NOT NULL
GROUP BY 
    t.movie_id, t.title, t.production_year, mk.keywords
ORDER BY 
    t.production_year DESC, total_casts DESC;
