WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COALESCE(GROUP_CONCAT(DISTINCT mi.info ORDER BY mi.info_type_id), 'N/A') AS movie_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id IS NOT NULL
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id
    WHERE 
        t.production_year > 2000 -- focusing on movies produced after 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
summary AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies,
        STRING_AGG(DISTINCT actor_names, '; ') AS all_actors,
        SUM(keyword_count) AS total_keywords,
        COUNT(DISTINCT company_type) AS unique_company_types,
        MAX(LENGTH(movie_info)) AS longest_info_length  -- finding longest info text
    FROM 
        movie_details
    GROUP BY 
        production_year
    ORDER BY 
        production_year DESC
)
SELECT 
    production_year,
    movie_count,
    movies,
    all_actors,
    total_keywords,
    unique_company_types,
    longest_info_length
FROM 
    summary
WHERE 
    movie_count > 5 -- only showing years with more than 5 movies
LIMIT 10; -- limiting the result to the most recent years
