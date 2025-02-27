WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(CASE WHEN k.keyword IS NOT NULL THEN k.keyword END) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.title, t.production_year, c.kind
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        company_type,
        keywords,
        cast_count,
        aka_names,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    *
FROM 
    top_movies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, 
    cast_count DESC;
