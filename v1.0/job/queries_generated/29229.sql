WITH movie_rankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_distribution AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.aka_names,
    mr.cast_count,
    kd.keywords,
    kd.keyword_count,
    cd.companies,
    cd.company_types
FROM 
    movie_rankings mr
LEFT JOIN 
    keyword_distribution kd ON mr.movie_id = kd.movie_id
LEFT JOIN 
    company_details cd ON mr.movie_id = cd.movie_id
ORDER BY 
    mr.production_year DESC, mr.cast_count DESC;
