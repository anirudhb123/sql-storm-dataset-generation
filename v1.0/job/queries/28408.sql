
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COALESCE(COUNT(DISTINCT ca.person_id), 0) AS cast_count,
        COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN 
        movie_keyword mw ON mw.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mw.keyword_id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
),
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        keywords,
        cast_count,
        company_count,
        RANK() OVER (ORDER BY cast_count DESC, company_count DESC, production_year DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    rm.rank,
    rm.movie_title,
    rm.production_year,
    rm.aka_names,
    rm.keywords,
    rm.cast_count,
    rm.company_count
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
