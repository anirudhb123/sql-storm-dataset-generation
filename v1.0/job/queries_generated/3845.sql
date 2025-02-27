WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
),
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(dk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    (SELECT 
         AVG(p.info) 
     FROM 
         person_info p 
     WHERE 
         p.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = (SELECT t.id FROM aka_title t WHERE t.title = tm.title LIMIT 1))
    ) AS avg_person_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT t.id FROM aka_title t WHERE t.title = tm.title LIMIT 1)
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    DistinctKeywords dk ON dk.movie_id = (SELECT t.id FROM aka_title t WHERE t.title = tm.title LIMIT 1)
GROUP BY 
    tm.title, tm.production_year, dk.keywords
ORDER BY 
    tm.production_year DESC, total_cast_members DESC;
