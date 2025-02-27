WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
),
actor_details AS (
    SELECT 
        p.id AS person_id,
        a.name AS actor_name,
        c.movie_id,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
),
smart_movie_summary AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        STRING_AGG(DISTINCT ad.actor_name, ', ') AS cast_names,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
        COUNT(DISTINCT ad.person_id) AS number_of_actors
    FROM 
        movie_details md
    LEFT JOIN 
        actor_details ad ON md.movie_id = ad.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year
)
SELECT 
    movie_title,
    production_year,
    number_of_actors,
    cast_names,
    keywords
FROM 
    smart_movie_summary
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC,
    number_of_actors DESC;
