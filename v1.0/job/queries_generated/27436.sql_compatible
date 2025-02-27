
WITH popular_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        a.id, a.title, a.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
movie_details AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        STRING_AGG(DISTINCT CONCAT(cn.name, ' (', ct.kind, ')'), ', ') AS companies,
        STRING_AGG(DISTINCT it.info, ', ') AS additional_info
    FROM 
        popular_movies pm
    JOIN 
        movie_companies mc ON pm.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info mi ON pm.movie_id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        pm.movie_id, pm.title, pm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.companies,
    md.additional_info,
    pm.total_cast,
    pm.aka_names,
    pm.keywords
FROM 
    movie_details md
JOIN 
    popular_movies pm ON md.movie_id = pm.movie_id
ORDER BY 
    pm.total_cast DESC, 
    md.production_year DESC
LIMIT 20;
