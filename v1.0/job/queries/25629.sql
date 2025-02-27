WITH movie_data AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT n.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        name n ON ca.person_id = n.imdb_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.title, a.production_year, c.name
),
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        cast_count,
        keywords,
        actor_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    rank,
    movie_title,
    production_year,
    company_name,
    cast_count,
    keywords,
    actor_names
FROM 
    ranked_movies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, rank;
