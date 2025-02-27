WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
    COALESCE(p.info, 'No Info Available') AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    (SELECT 
        DISTINCT person_id, 
        STRING_AGG(info, '; ') AS info 
     FROM 
        person_info 
     WHERE 
        info IS NOT NULL 
     GROUP BY 
        person_id) p ON p.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id)
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
