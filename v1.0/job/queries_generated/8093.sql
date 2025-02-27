WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        COUNT(DISTINCT mk.keyword) AS num_keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 1990
    GROUP BY 
        t.id
), CompStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.num_cast_members,
    cs.num_companies,
    ms.num_keywords
FROM 
    MovieStats ms
LEFT JOIN 
    CompStats cs ON ms.movie_id = cs.movie_id
ORDER BY 
    ms.production_year DESC, 
    ms.num_cast_members DESC, 
    cs.num_companies DESC
LIMIT 100;
