WITH movie_cast AS (
    SELECT 
        t.title,
        t.production_year,
        array_agg(DISTINCT a.name) AS cast_names,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id
),
company_info AS (
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
keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mc.title,
    mc.production_year,
    mc.cast_names,
    mc.total_cast,
    coalesce(ci.company_names, '{}') AS company_names,
    coalesce(ci.company_types, '{}') AS company_types,
    coalesce(ki.keywords, 'No Keywords') AS keywords
FROM 
    movie_cast mc
LEFT JOIN 
    company_info ci ON mc.production_year = ci.movie_id
LEFT JOIN 
    keyword_info ki ON mc.production_year = ki.movie_id
WHERE 
    mc.total_cast > 3
ORDER BY 
    mc.production_year DESC, mc.title;
