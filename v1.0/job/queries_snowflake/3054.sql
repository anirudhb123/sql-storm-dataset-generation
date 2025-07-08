
WITH MovieYear AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    my.title,
    my.production_year,
    COALESCE(my.cast_count, 0) AS cast_count,
    ci.company_name,
    ci.company_type
FROM 
    MovieYear my
LEFT JOIN 
    CompanyInfo ci ON my.movie_id = ci.movie_id
WHERE 
    my.production_year > (SELECT AVG(production_year) FROM aka_title WHERE production_year IS NOT NULL)
ORDER BY 
    my.production_year DESC, 
    my.cast_count DESC
LIMIT 100;
