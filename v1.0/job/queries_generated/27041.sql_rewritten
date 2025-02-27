WITH 
    RankedMovies AS (
        SELECT 
            m.id AS movie_id,
            m.title AS movie_title,
            m.production_year,
            ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
        FROM 
            title m
        JOIN 
            movie_info mi ON m.id = mi.movie_id
        JOIN 
            complete_cast cc ON m.id = cc.movie_id
        JOIN 
            cast_info ci ON cc.subject_id = ci.person_id
        GROUP BY 
            m.id, m.title, m.production_year
    ),
    MoviesWithKeywords AS (
        SELECT 
            rm.movie_id,
            rm.movie_title,
            rm.production_year,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            RankedMovies rm
        LEFT JOIN 
            movie_keyword mk ON rm.movie_id = mk.movie_id
        LEFT JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            rm.rank <= 10  
        GROUP BY 
            rm.movie_id, rm.movie_title, rm.production_year
    )
SELECT 
    mwk.movie_title,
    mwk.production_year,
    mwk.keywords,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) * 100 AS note_percentage
FROM 
    MoviesWithKeywords mwk
JOIN 
    complete_cast cc ON mwk.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
GROUP BY 
    mwk.movie_title, mwk.production_year, mwk.keywords
ORDER BY 
    mwk.production_year DESC, total_cast DESC;