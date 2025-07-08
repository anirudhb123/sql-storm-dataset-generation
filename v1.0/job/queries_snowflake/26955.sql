
WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        rt.role,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.movie_id = c.movie_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        a.production_year >= 2000 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY 
        a.title, a.production_year, rt.role
    ORDER BY 
        cast_count DESC
    LIMIT 10
), detailed_info AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.role,
        rt.cast_count,
        LISTAGG(DISTINCT CONCAT(ak.name, ' (', ak.id, ')'), ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        ranked_titles rt
    JOIN 
        cast_info c ON rt.title = (SELECT title FROM aka_title WHERE movie_id = c.movie_id)
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        rt.title, rt.production_year, rt.role, rt.cast_count
)
SELECT 
    di.title,
    di.production_year,
    di.role,
    di.cast_count,
    di.cast_names
FROM 
    detailed_info di
WHERE 
    di.cast_count > 5
ORDER BY 
    di.cast_count DESC, di.title;
