
WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), 
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS primary_info,
        AVG(CASE WHEN c.status_id = 1 THEN c.status_id END) AS avg_comp_status
    FROM 
        title t
    LEFT JOIN 
        complete_cast c ON t.id = c.movie_id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id 
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    CONCAT(mr.actor_name, ' as ', mr.role_name) AS actor_role,
    md.keyword_count,
    md.primary_info,
    md.avg_comp_status
FROM 
    MovieDetails md
JOIN 
    MovieRoles mr ON md.title = mr.actor_name
WHERE 
    md.production_year > 2000
    AND md.keyword_count > 0
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC, 
    mr.role_order
LIMIT 10;
