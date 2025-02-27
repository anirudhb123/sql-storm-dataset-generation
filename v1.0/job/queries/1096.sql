WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.id
), 

TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.rank <= 3 THEN 'Top 3'
            ELSE 'Other'
        END AS category
    FROM 
        RankedMovies rm
)

SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = tm.title_id) AS total_cast,
    SUM(CASE WHEN ci.person_role_id = 1 THEN 1 ELSE 0 END) AS lead_roles
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = tm.title_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = tm.title_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.title_id
WHERE 
    tm.category = 'Top 3' 
    AND tm.production_year BETWEEN 2000 AND 2023
GROUP BY 
    tm.title_id, tm.title, tm.production_year, mk.keywords
ORDER BY 
    tm.production_year DESC, total_cast DESC;
