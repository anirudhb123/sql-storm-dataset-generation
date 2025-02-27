WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS kind_of_movie,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aliases,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        kind_type c ON t.kind_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (
            SELECT person_id 
            FROM cast_info ci 
            WHERE ci.movie_id = t.id
        )
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
), 
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.kind_of_movie,
    md.aliases,
    md.keyword_count,
    cd.total_cast,
    cd.roles
FROM 
    movie_details md
JOIN 
    cast_details cd ON md.movie_title = cd.movie_id
ORDER BY 
    md.production_year DESC,
    md.movie_title;
