WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        a.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id
)
SELECT 
    tm.title,
    tm.production_year,
    mk.keywords,
    COALESCE(COUNT(m.id), 0) AS company_count,
    COALESCE(AVG(strlen(m.note)), 0) AS avg_note_length
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies m ON tm.title = m.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
LEFT JOIN 
    company_name cn ON m.company_id = cn.id
GROUP BY 
    tm.title, tm.production_year, mk.keywords
HAVING 
    COUNT(m.id) > 0 OR COUNT(m.id) IS NULL
ORDER BY 
    tm.production_year DESC, tm.title ASC;
