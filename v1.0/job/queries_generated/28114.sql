WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ct.kind AS company_type,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, ct.kind
),

most_prolific_actors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        COUNT(ci.movie_id) >= 5
    ORDER BY 
        movies_count DESC
    LIMIT 10
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.company_type,
    md.cast_count,
    pa.actor_name,
    pa.movies_count
FROM 
    movie_details md
JOIN 
    most_prolific_actors pa ON md.cast_count > 5
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
