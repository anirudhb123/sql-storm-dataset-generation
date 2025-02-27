WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ARRAY_AGG(DISTINCT c.name) AS company_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        company_name c ON m.company_id = c.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),

cast_info_agg AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),

movie_details AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.company_count,
        r.company_names,
        ca.cast_count,
        ca.cast_names
    FROM 
        ranked_movies r
    LEFT JOIN 
        cast_info_agg ca ON r.movie_id = ca.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.company_names,
    md.cast_count,
    md.cast_names
FROM 
    movie_details md
WHERE 
    md.company_count > 2
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC
LIMIT 10;
