
WITH movie_stats AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') THEN CAST(mi.info AS INTEGER) END) AS avg_duration
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title
),
ranked_movies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.total_cast,
        ms.total_companies,
        ms.avg_duration,
        RANK() OVER (ORDER BY ms.total_cast DESC, ms.avg_duration DESC) AS movie_rank
    FROM 
        movie_stats ms
)
SELECT 
    r.title,
    r.total_cast,
    r.total_companies,
    COALESCE(r.avg_duration, 0) AS avg_duration,
    CASE 
        WHEN r.total_cast > 10 THEN 'Large Cast'
        WHEN r.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT 
        LISTAGG(DISTINCT cn.name, ', ') 
     FROM 
        company_name cn 
     INNER JOIN 
        movie_companies mc ON cn.id = mc.company_id 
     WHERE 
        mc.movie_id = r.movie_id 
    ) AS companies_involved
FROM 
    ranked_movies r
WHERE 
    r.movie_rank <= 10
ORDER BY 
    r.total_cast DESC, 
    r.avg_duration DESC;
