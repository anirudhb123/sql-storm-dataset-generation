
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
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
        rank <= 5
)

SELECT 
    tm.title,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS non_null_cast_notes,
    COUNT(DISTINCT mci.company_id) AS production_companies,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mci ON tm.movie_id = mci.movie_id
LEFT JOIN 
    company_name cn ON mci.company_id = cn.id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    tm.production_year DESC, non_null_cast_notes DESC;
