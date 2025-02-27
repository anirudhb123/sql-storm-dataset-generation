WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id
), 
MovieWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id
),
TopMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.keywords
    FROM 
        MovieWithKeywords mwk
    WHERE 
        mwk.movie_id IN (SELECT movie_id FROM RankedMovies WHERE rank <= 10)
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keywords,
    GROUP_CONCAT(DISTINCT c.note ORDER BY c.note) AS cast_notes,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
GROUP BY 
    tm.movie_id
ORDER BY 
    tm.production_year DESC, tm.title;
