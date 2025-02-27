WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT mi.info) AS movie_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year, ct.kind
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
    ORDER BY 
        t.production_year DESC
),
output AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_type,
        md.actors,
        md.keywords,
        md.movie_info,
        CASE 
            WHEN md.production_year > 2000 THEN 'Modern Era'
            WHEN md.production_year BETWEEN 1990 AND 2000 THEN '90s Classics'
            ELSE 'Old School'
        END AS era_classification
    FROM 
        movie_details md
)

SELECT 
    era_classification,
    COUNT(*) AS total_movies,
    GROUP_CONCAT(title) AS movie_titles,
    GROUP_CONCAT(actors) AS actors_in_movies
FROM 
    output
GROUP BY 
    era_classification
ORDER BY 
    total_movies DESC;
