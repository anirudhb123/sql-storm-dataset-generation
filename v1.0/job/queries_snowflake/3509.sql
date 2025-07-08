
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id, a.title, a.production_year
), TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
), MovieKeywords AS (
    SELECT 
        m.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.person_id) FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = t.title LIMIT 1)) AS total_cast
FROM 
    TopMovies t
LEFT JOIN 
    MovieKeywords mk ON t.title = mk.title
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    total_cast DESC;
