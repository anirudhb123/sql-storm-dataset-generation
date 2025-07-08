
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ra.name AS director_name,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_size
    FROM
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ra ON mc.company_id = ra.person_id
    GROUP BY 
        mt.title, 
        mt.production_year, 
        ra.name
),
TopDirectors AS (
    SELECT 
        director_name,
        production_year,
        total_cast,
        rank_by_cast_size
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_size <= 3
)
SELECT 
    td.director_name,
    AVG(td.total_cast) AS avg_cast_size,
    LISTAGG(tm.title || ' (' || tm.production_year || ')', ', ') WITHIN GROUP (ORDER BY tm.title) AS related_movies
FROM 
    TopDirectors td
LEFT JOIN 
    aka_title tm ON td.production_year = tm.production_year
WHERE 
    (td.total_cast > 0 OR td.total_cast IS NULL)
GROUP BY 
    td.director_name
HAVING 
    COUNT(DISTINCT td.production_year) >= 2
ORDER BY 
    avg_cast_size DESC
LIMIT 10;
