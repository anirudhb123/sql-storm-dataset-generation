WITH movie_details AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles,
        STRING_AGG(DISTINCT cn.name, ', ') AS character_names
    FROM 
        aka_title a
    LEFT JOIN
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        char_name cn ON ci.person_id = cn.id
    WHERE 
        a.production_year >= 2000 AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY 
        a.id
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY md.cast_count DESC, md.production_year ASC) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.noted_roles,
    rm.character_names
FROM 
    ranked_movies rm
WHERE 
    rm.cast_count > (SELECT AVG(cast_count) FROM movie_details)
    AND rm.rank <= 10
ORDER BY 
    rm.cast_count DESC
;

SELECT 
    DISTINCT on (m.title) 
    m.title, 
    CASE 
        WHEN cc.note IS NOT NULL THEN 'Notable' 
        ELSE 'Regular' 
    END AS role_type
FROM 
    aka_title m
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
WHERE 
    m.production_year > 2010 
    AND EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = m.id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%'))
ORDER BY 
    m.title, 
    role_type DESC;
