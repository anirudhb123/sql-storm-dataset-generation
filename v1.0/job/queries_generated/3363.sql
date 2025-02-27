WITH MovieStats AS (
    SELECT 
        mt.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) * 100 AS percentage_with_note,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    ms.movie_title,
    ms.total_cast,
    ms.percentage_with_note,
    ci.company_name,
    ci.company_type,
    ci.total_companies,
    DENSE_RANK() OVER (ORDER BY ms.total_cast DESC) AS cast_rank
FROM 
    MovieStats ms
LEFT JOIN 
    CompanyInfo ci ON ms.movie_title = ci.movie_id 
WHERE 
    ci.total_companies > 1
ORDER BY 
    ms.total_cast DESC, ms.movie_title ASC;
