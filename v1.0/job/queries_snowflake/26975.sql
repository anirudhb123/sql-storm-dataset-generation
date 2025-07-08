
WITH ranked_movies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        c.role_id,
        p.name AS person_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY p.name) AS rank
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    JOIN 
        title AS t ON c.movie_id = t.id
    JOIN 
        name AS p ON c.person_id = p.imdb_id
    WHERE 
        t.production_year > 2000  
        AND LENGTH(a.name) > 5    
),
aggregated_roles AS (
    SELECT
        movie_title,
        production_year,
        COUNT(DISTINCT aka_id) AS total_aka_names,
        COUNT(DISTINCT role_id) AS distinct_roles,
        LISTAGG(DISTINCT person_name, ', ') WITHIN GROUP (ORDER BY person_name) AS cast_members
    FROM 
        ranked_movies
    WHERE 
        rank <= 3  
    GROUP BY 
        movie_title, production_year
)
SELECT 
    production_year,
    movie_title,
    total_aka_names,
    distinct_roles,
    cast_members
FROM 
    aggregated_roles
ORDER BY 
    production_year DESC, total_aka_names DESC;
