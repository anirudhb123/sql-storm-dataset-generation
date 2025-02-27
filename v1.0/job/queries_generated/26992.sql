WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(a.name) AS actors,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COALESCE(c.kind, 'Unknown') AS company_type,
        MIN(k.keyword) AS first_keyword
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, c.kind
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actors,
        md.keyword_count,
        md.company_type,
        md.first_keyword,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.actors,
    rm.keyword_count,
    rm.company_type,
    rm.first_keyword
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year, rm.rank;
