WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT kc.id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT kc.id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        aka_title ak ON m.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.aka_names,
        rm.keyword_count,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.aka_names,
    tm.keyword_count,
    tm.company_count,
    co.name AS production_company,
    ARRAY_AGG(DISTINCT pi.info) AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
LEFT JOIN 
    movie_companies mco ON tm.movie_id = mco.movie_id
LEFT JOIN 
    company_name co ON mco.company_id = co.id
GROUP BY 
    tm.title, tm.production_year, tm.aka_names, tm.keyword_count, tm.company_count, co.name
ORDER BY 
    tm.production_year DESC, tm.keyword_count DESC;
