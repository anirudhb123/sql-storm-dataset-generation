WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS main_actor,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.movie_id) AS company_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND a.name IS NOT NULL
        AND ci.nr_order = 1  -- Get only the main actor
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        main_actor,
        company_type,
        keywords,
        company_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY company_count DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    movie_id,
    title,
    production_year,
    main_actor,
    company_type,
    keywords,
    company_count,
    rank
FROM 
    ranked_movies
WHERE 
    rank <= 5  -- Top 5 movies per production year
ORDER BY 
    production_year, rank;
