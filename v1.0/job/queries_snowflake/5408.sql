
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
        AND a.production_year BETWEEN 2000 AND 2020
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_name,
    LISTAGG(rm.keyword, ', ') WITHIN GROUP (ORDER BY rm.keyword) AS keywords
FROM 
    RankedMovies rm
WHERE 
    rm.rn = 1
GROUP BY 
    rm.title, rm.production_year, rm.company_name
ORDER BY 
    rm.production_year DESC;
