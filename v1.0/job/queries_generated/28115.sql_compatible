
WITH movie_info_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
actor_info AS (
    SELECT 
        p.id AS person_id,
        CONCAT_WS(' ', a.name, p.name) AS full_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        p.id, a.name
)
SELECT 
    m.title,
    m.production_year,
    m.keywords,
    m.companies,
    m.cast_count,
    a.full_name,
    a.movie_count,
    a.movies
FROM 
    movie_info_details m
JOIN 
    actor_info a ON m.cast_count > 0
ORDER BY 
    m.production_year DESC, 
    m.title ASC;
