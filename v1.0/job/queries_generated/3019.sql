WITH movie_stats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords,
        AVG(ci.nr_order) AS avg_role_order,
        STRING_AGG(DISTINCT cn.name, ', ') AS comp_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year 
),
cast_details AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS role_rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.total_keywords,
    ms.avg_role_order,
    cd.person_id,
    cd.movies_count,
    cd.role_rank,
    COALESCE(cd.movies_count, 0) AS person_movies_count
FROM 
    movie_stats ms
LEFT JOIN 
    cast_details cd ON ms.movie_id = cd.person_id
WHERE 
    (ms.production_year >= 2000 OR ms.total_cast > 10)
    AND (ms.comp_names IS NOT NULL AND ms.comp_names <> '')
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC;
