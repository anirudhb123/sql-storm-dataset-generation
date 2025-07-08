
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
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
),
CompanyAndInfo AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        LISTAGG(mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    WHERE 
        c.country_code = 'USA'
    GROUP BY 
        m.movie_id, c.name
)
SELECT 
    tm.title,
    tm.production_year,
    cai.company_name,
    cai.movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyAndInfo cai ON tm.movie_id = cai.movie_id
WHERE 
    cai.movie_info IS NOT NULL
UNION ALL
SELECT 
    DISTINCT t.title,
    t.production_year,
    NULL AS company_name,
    NULL AS movie_info
FROM 
    aka_title t
WHERE 
    t.production_year NOT IN (SELECT production_year FROM TopMovies);
