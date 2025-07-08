
WITH movie_ranked AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT ci.person_id) AS total_cast, 
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
keyword_count AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id, 
        LISTAGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mr.title,
    mr.production_year,
    mr.total_cast,
    mr.avg_order,
    kc.keyword_total,
    ci.company_names
FROM 
    movie_ranked mr
LEFT JOIN 
    keyword_count kc ON mr.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
LEFT JOIN 
    company_info ci ON mr.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
WHERE 
    mr.rank <= 10
    AND (mr.total_cast IS NOT NULL OR mr.avg_order > 0)
ORDER BY 
    mr.production_year DESC, 
    mr.total_cast DESC;
