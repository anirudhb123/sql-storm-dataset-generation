
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopCastMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
TopKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    k.keywords
FROM 
    TopCastMovies m
LEFT JOIN 
    TopKeywords k ON m.movie_id = k.movie_id
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
