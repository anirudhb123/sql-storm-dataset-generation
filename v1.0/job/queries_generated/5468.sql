WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_ratio,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name n ON a.person_id = n.imdb_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        num_cast DESC
    LIMIT 10
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.num_cast,
    rm.female_ratio,
    rm.keywords,
    COUNT(mc.company_id) AS num_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.num_cast, rm.female_ratio, rm.keywords
ORDER BY 
    num_companies DESC;
