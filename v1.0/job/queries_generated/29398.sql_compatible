
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT p.info, ', ') AS person_info,
        m.name AS company_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        person_info p ON c.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, m.name
    HAVING 
        COUNT(DISTINCT k.id) > 5
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    keywords,
    actor_count,
    person_info
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, actor_count DESC;
