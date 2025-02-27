WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS companies
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.id, m.title, m.production_year
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keywords,
        md.companies,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY LENGTH(md.cast_names) DESC) AS cast_rank
    FROM 
        movie_data md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_names,
    rm.keywords,
    rm.companies,
    rm.cast_rank
FROM 
    ranked_movies rm
WHERE 
    rm.cast_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_rank ASC;

This query is designed to benchmark string processing by aggregating string data associated with movies, including the names of cast members, keywords related to them, and companies involved in their production. The results feature the top 5 movies for each production year ranked by the total length of the cast names.
