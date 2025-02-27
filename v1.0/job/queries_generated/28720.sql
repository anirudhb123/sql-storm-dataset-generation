WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        t.kind AS movie_kind,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS production_companies,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info ca ON m.id = ca.movie_id
    JOIN 
        title t ON m.id = t.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, t.kind
),

top_movies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        movie_details
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    movie_kind,
    production_companies,
    keywords,
    cast_count
FROM 
    top_movies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, 
    cast_count DESC;
