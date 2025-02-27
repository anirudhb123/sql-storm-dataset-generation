WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        c.kind AS company_type,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, k.keyword, c.kind
), 
production_year_stats AS (
    SELECT 
        production_year,
        COUNT(DISTINCT title_id) AS total_movies,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        movie_details
    GROUP BY 
        production_year
)
SELECT 
    md.*,
    pys.total_movies,
    pys.keywords
FROM 
    movie_details md
JOIN 
    production_year_stats pys ON md.production_year = pys.production_year
ORDER BY 
    md.production_year DESC, 
    md.title;
