WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT p.name) AS cast
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        t.id
),
UniqueKeywordCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword) AS unique_keyword_count
    FROM 
        MovieInfo
    GROUP BY 
        movie_id
)
SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.keywords,
    mi.companies,
    mi.cast,
    ukc.unique_keyword_count
FROM 
    MovieInfo mi
JOIN 
    UniqueKeywordCount ukc ON mi.movie_id = ukc.movie_id
WHERE 
    mi.production_year BETWEEN 1990 AND 2023
ORDER BY 
    unique_keyword_count DESC, 
    mi.production_year DESC;
