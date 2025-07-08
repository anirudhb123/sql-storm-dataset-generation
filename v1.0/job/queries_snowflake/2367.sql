
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    LISTAGG(DISTINCT kc.keyword, ', ') AS keywords,
    COALESCE((SELECT COUNT(*) 
              FROM movie_info mi 
              WHERE mi.movie_id = tm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')), 0) AS box_office_count,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 0 THEN 'Has Production Companies'
        ELSE 'No Production Companies'
    END AS prod_company_status
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, ak.name
HAVING 
    COUNT(DISTINCT ak.name) > 1 OR COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    tm.production_year DESC, tm.title;
