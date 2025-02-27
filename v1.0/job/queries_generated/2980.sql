WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        TopMovies tm
    INNER JOIN 
        movie_keyword mk ON tm.title = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE STRING_AGG(mk.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_actors
FROM 
    TopMovies tm
LEFT JOIN 
    movie_link ml ON tm.title = ml.movie_id
LEFT JOIN 
    movie_companies mc ON tm.title = mc.movie_id
LEFT JOIN 
    complete_cast cc ON tm.title = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, total_actors DESC;
