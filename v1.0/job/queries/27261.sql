
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CAST(p.info AS FLOAT)) AS avg_rating
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword ILIKE '%drama%'
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    keywords,
    companies,
    cast_count,
    avg_rating
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, 
    avg_rating DESC;
