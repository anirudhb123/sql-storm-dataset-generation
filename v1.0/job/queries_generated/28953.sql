WITH movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        COALESCE(cs.total_cast, 0) AS total_cast,
        cs.roles
    FROM 
        title t
    LEFT JOIN 
        movie_keyword_counts mkc ON t.id = mkc.movie_id
    LEFT JOIN 
        cast_summary cs ON t.id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.total_cast,
    md.roles,
    cp.name AS company_name,
    ct.kind AS company_type
FROM 
    movie_details md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name cp ON mc.company_id = cp.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    md.keyword_count > 3
ORDER BY 
    md.total_cast DESC,
    md.keyword_count DESC
LIMIT 10;
