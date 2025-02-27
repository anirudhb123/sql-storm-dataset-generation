WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ci.kind) AS company_types
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        m.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
genre_count AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT km.keyword_id) AS keyword_count
    FROM 
        movie_keyword km
    JOIN 
        movie_details m ON km.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_keyword,
    md.cast_names,
    md.company_names,
    md.company_types,
    gc.keyword_count
FROM 
    movie_details md
JOIN 
    genre_count gc ON md.movie_id = gc.movie_id
ORDER BY 
    md.production_year DESC, 
    gc.keyword_count DESC
LIMIT 100;
