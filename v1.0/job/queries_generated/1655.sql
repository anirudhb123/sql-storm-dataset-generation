WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
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
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    JSON_AGG(DISTINCT p.name) AS cast_names
FROM 
    RankedMovies m
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
WHERE 
    m.rank <= 5
GROUP BY 
    m.movie_id, m.title, m.production_year, mk.keywords
ORDER BY 
    m.production_year DESC, cast_count DESC;
