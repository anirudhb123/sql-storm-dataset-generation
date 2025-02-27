WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ck.keyword) AS keyword_count
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name AS ak ON ci.person_role_id = ak.id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS ck ON mk.keyword_id = ck.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, ct.kind
)
SELECT 
    title,
    production_year,
    company_type,
    aka_names,
    company_count,
    keyword_count
FROM 
    RankedMovies
WHERE 
    company_count > 1
ORDER BY 
    production_year DESC, title ASC;
