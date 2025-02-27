WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        rk.rank,
        COUNT(c.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        company_name co ON t.id = co.imdb_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    CROSS JOIN (
        SELECT 
            title, 
            ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(c.person_id) DESC) AS rank
        FROM 
            aka_title t
        LEFT JOIN 
            complete_cast cc ON t.id = cc.movie_id
        LEFT JOIN 
            cast_info c ON cc.subject_id = c.person_id
        GROUP BY 
            t.title, t.production_year
    ) rk
    WHERE 
        t.production_year >= 2000 
        AND (mi.note IS NULL OR LOWER(mi.note) NOT LIKE '%deleted%')
    GROUP BY 
        t.title, t.production_year, rk.rank
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE((SELECT AVG(actor_count) FROM ranked_movies), 0) AS average_actor_count,
    CASE 
        WHEN rm.actor_count > (SELECT MAX(actor_count) FROM ranked_movies) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_indicator
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
