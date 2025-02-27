WITH movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        m.production_year,
        k.keyword AS genre
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
company_movie AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
detailed_movie_info AS (
    SELECT 
        mc.movie_id,
        mc.movie_title,
        mc.production_year,
        mc.cast_names,
        cm.company_names,
        cm.company_types,
        ROW_NUMBER() OVER (PARTITION BY mc.production_year ORDER BY mc.movie_title) AS rank
    FROM 
        movie_cast mc
    JOIN 
        company_movie cm ON mc.movie_id = cm.movie_id
)
SELECT 
    movie_title,
    production_year,
    cast_names,
    company_names,
    company_types
FROM 
    detailed_movie_info
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, movie_title;
