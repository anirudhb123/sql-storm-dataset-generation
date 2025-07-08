
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
person_info_details AS (
    SELECT 
        pi.person_id,
        LISTAGG(DISTINCT pi.info, '; ') AS info_details
    FROM
        person_info pi
    GROUP BY
        pi.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(pid.info_details, 'No personal info') AS personal_info,
    COUNT(ci.id) AS cast_size,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_cast_order
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    person_info_details pid ON ci.person_id = pid.person_id
WHERE 
    rm.rn <= 10
GROUP BY 
    rm.title, rm.production_year, mk.keywords, pid.info_details
ORDER BY 
    rm.production_year DESC, cast_size DESC;
