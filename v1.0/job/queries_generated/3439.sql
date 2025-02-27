WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS total_companies,
        MAX(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    cs.company_name,
    cs.company_type,
    cs.total_companies,
    cs.has_note,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY rm.movie_id) AS unique_actors,
    SUM(CASE WHEN ki.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    STRING_AGG(DISTINCT ki.keyword, ', ') FILTER (WHERE ki.keyword IS NOT NULL) AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.year_rank <= 5 
    AND (cs.total_companies IS NULL OR cs.has_note = 1)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cs.company_name, cs.company_type, cs.total_companies, cs.has_note
ORDER BY 
    rm.production_year DESC, unique_actors DESC;
