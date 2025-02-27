WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN ci.kind = 'cast' THEN ci.nr_order ELSE NULL END) AS avg_cast_order
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year > 2000
        AND cn.country_code = 'USA'
    GROUP BY 
        t.id
    ORDER BY 
        actor_count DESC
    LIMIT 10
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.avg_cast_order,
    mki.keyword
FROM 
    ranked_movies rm
JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    rm.actor_count DESC, 
    rm.avg_cast_order ASC;
