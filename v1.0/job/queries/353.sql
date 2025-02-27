
WITH movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), 
movie_info_agg AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mi.id) AS info_count,
        AVG(LENGTH(mi.info)) AS avg_info_length
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
), 
company_agg AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ma.movie_id,
    ma.title,
    ma.production_year,
    ma.info_count,
    ma.avg_info_length,
    mc.num_cast_members,
    mc.cast_names,
    ca.num_companies,
    ca.company_names
FROM 
    movie_info_agg ma
JOIN 
    movie_cast mc ON ma.movie_id = mc.movie_id
LEFT JOIN 
    company_agg ca ON ma.movie_id = ca.movie_id
WHERE 
    ma.production_year >= 2000
ORDER BY 
    ma.production_year DESC,
    mc.num_cast_members DESC;
