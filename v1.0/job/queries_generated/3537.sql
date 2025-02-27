WITH MovieRankings AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS total_actors,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    mr.title,
    mr.production_year,
    mr.total_actors,
    ci.company_name,
    ci.company_type,
    kc.keyword_count
FROM 
    MovieRankings mr
LEFT JOIN 
    CompanyInfo ci ON mr.title = ci.movie_id
LEFT JOIN 
    KeywordCounts kc ON mr.id = kc.movie_id
WHERE 
    mr.year_rank = 1
    AND (ci.company_rank IS NULL OR ci.company_type LIKE 'Production%')
ORDER BY 
    mr.production_year DESC, mr.total_actors DESC;
