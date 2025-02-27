WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cp.kind, ', ') AS company_types
    FROM 
        aka_title t
    JOIN 
        aka_name ak ON ak.movie_id = t.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id 
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    LEFT JOIN 
        company_type cp ON cp.id = mc.company_type_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.cast_count,
    md.keywords,
    COALESCE(ct.kind, 'Unknown') AS main_company_type
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON mc.movie_id = md.movie_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC;
