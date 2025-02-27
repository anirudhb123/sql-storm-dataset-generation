WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY tk.keyword DESC) AS rank,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
)
SELECT 
    tm.title AS Movie_Title,
    COALESCE(a.name, 'Unknown') AS Actor_Name,
    tm.production_year AS Production_Year,
    COALESCE(cct.kind, 'Others') AS Company_Type,
    (SELECT COUNT(*)
     FROM complete_cast cc
     WHERE cc.movie_id = tm.movie_id) AS Cast_Count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
WHERE 
    tm.company_count > 1
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
