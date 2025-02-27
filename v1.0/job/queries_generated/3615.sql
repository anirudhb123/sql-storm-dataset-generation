WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MostCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(i.info, 'No Info') AS info,
    COUNT(DISTINCT cc.person_id) AS cast_count
FROM 
    MostCastMovies m
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    movie_info i ON m.movie_id = i.movie_id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
WHERE 
    i.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
    OR m.production_year > 2000
GROUP BY 
    m.movie_id, m.title, m.production_year, mk.keywords, i.info
ORDER BY 
    m.production_year DESC, cast_count DESC;
