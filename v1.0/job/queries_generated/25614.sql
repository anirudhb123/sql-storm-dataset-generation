WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT c.id) AS total_cast,
        GROUP_CONCAT(DISTINCT comp.name) AS companies,
        GROUP_CONCAT(DISTINCT p.info) AS person_info
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name comp ON mc.company_id = comp.id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id AND p.info_type_id IN (1, 2) -- Assuming info_type_id 1 and 2 are relevant
    WHERE 
        t.production_year >= 2000 AND 
        t.production_year <= 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordCounts AS (
    SELECT 
        keyword,
        COUNT(movie_id) AS keyword_count
    FROM 
        movie_keyword
    JOIN 
        aka_title ON movie_keyword.movie_id = aka_title.id
    WHERE 
        aka_title.production_year >= 2000
    GROUP BY 
        keyword
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.total_cast,
    md.companies,
    kc.keyword,
    kc.keyword_count,
    md.person_info
FROM 
    MovieDetails md
JOIN 
    KeywordCounts kc ON md.keyword = kc.keyword
ORDER BY 
    md.production_year DESC, 
    kc.keyword_count DESC;
