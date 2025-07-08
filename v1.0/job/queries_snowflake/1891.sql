
WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY c.nr_order DESC) AS rank_order
    FROM 
        aka_title a
    JOIN 
        movie_info m ON a.id = m.movie_id
    JOIN 
        movie_keyword k ON a.id = k.movie_id
    JOIN 
        keyword kw ON k.keyword_id = kw.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        kw.keyword LIKE '%drama%' 
        AND a.production_year BETWEEN 2000 AND 2020
)
SELECT 
    rm.title, 
    rm.production_year, 
    p.name AS lead_actor,
    COALESCE(COUNT(DISTINCT mcc.company_id), 0) AS production_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.title = cc.title
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    movie_companies mcc ON rm.title = mcc.title
WHERE 
    rm.rank_order = 1
GROUP BY 
    rm.title, rm.production_year, p.name
HAVING 
    COUNT(DISTINCT mcc.company_id) > 1
ORDER BY 
    rm.production_year DESC, rm.title;
