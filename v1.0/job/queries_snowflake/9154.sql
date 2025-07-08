
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS total_cast, 
        ARRAY_AGG(DISTINCT c.kind) AS company_kinds
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
)
SELECT 
    r.movie_id, 
    r.title, 
    r.production_year, 
    r.total_cast, 
    r.company_kinds, 
    ARRAY_AGG(DISTINCT ak.name) AS aka_names
FROM 
    RankedMovies r
JOIN 
    aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = r.movie_id)
GROUP BY 
    r.movie_id, r.title, r.production_year, r.total_cast, r.company_kinds
ORDER BY 
    r.total_cast DESC;
