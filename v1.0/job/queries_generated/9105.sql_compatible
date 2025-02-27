
WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names, 
        STRING_AGG(DISTINCT cmt.kind, ', ') AS company_types 
    FROM 
        aka_title t 
        JOIN movie_companies mc ON t.movie_id = mc.movie_id 
        JOIN company_type cmt ON mc.company_type_id = cmt.id 
        JOIN aka_name ak ON ak.person_id = mc.company_id 
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
), 
cast_details AS (
    SELECT 
        c.movie_id, 
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names, 
        STRING_AGG(DISTINCT r.role, ', ') AS roles 
    FROM 
        cast_info c 
        JOIN name n ON c.person_id = n.imdb_id 
        JOIN role_type r ON c.role_id = r.id 
    GROUP BY 
        c.movie_id
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.aka_names, 
    cd.cast_names, 
    cd.roles, 
    md.company_types 
FROM 
    movie_details md 
    LEFT JOIN cast_details cd ON md.movie_id = cd.movie_id 
ORDER BY 
    md.production_year DESC, 
    md.title;
