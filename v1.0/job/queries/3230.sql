
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_count,
        t.id AS movie_id
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieKeywords AS (
    SELECT 
        t.id AS movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.role_id) FROM cast_info ci WHERE ci.movie_id = rm.movie_id AND ci.note IS NULL) AS role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_count <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
