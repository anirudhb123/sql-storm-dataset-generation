WITH enriched_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT CONCAT('(', ct.kind, ')'), ', ') AS company_types
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    em.movie_id,
    em.title,
    em.production_year,
    em.cast_count,
    em.aka_names,
    em.company_types,
    CASE 
        WHEN em.cast_count > 10 THEN 'Large Cast'
        WHEN em.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    enriched_movies em
WHERE 
    em.aka_names IS NOT NULL
ORDER BY 
    em.production_year DESC, 
    em.cast_count DESC;
