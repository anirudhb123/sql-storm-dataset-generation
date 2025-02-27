WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.kind,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword), 'No Keywords') AS keywords
    FROM 
        aka_title AS a
    JOIN 
        movie_info AS mi ON a.id = mi.movie_id
    JOIN 
        kind_type AS c ON a.kind_id = c.id
    LEFT JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year, c.kind
    ORDER BY 
        a.production_year DESC
    LIMIT 100
)
SELECT 
    rm.title,
    rm.production_year,
    rm.kind,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT p.info, ', ') AS director_info
FROM 
    RankedMovies AS rm
JOIN 
    movie_companies AS mc ON rm.id = mc.movie_id
LEFT JOIN 
    complete_cast AS cc ON rm.id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
LEFT JOIN 
    person_info AS p ON ci.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
GROUP BY 
    rm.title, rm.production_year, rm.kind
ORDER BY 
    production_companies DESC, rm.production_year DESC;
