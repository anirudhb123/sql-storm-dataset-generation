WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
        AND t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
avg_movie_years AS (
    SELECT 
        AVG(production_year) AS avg_year
    FROM 
        movie_details
),
actor_count AS (
    SELECT 
        COUNT(DISTINCT a.person_id) AS total_actors
    FROM 
        aka_name a
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    md.company_types,
    ay.avg_year,
    ac.total_actors
FROM 
    movie_details md,
    avg_movie_years ay,
    actor_count ac
ORDER BY 
    md.production_year DESC;
