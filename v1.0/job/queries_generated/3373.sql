WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_role
    FROM 
        aka_title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        ROW_NUMBER() OVER (ORDER BY md.actor_count DESC) AS rank
    FROM 
        movie_details md
    WHERE 
        md.production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    tm.actor_count,
    CASE 
        WHEN tm.has_role > 0 THEN 'Has Roles'
        ELSE 'No Roles'
    END AS role_status
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    tm.rank <= 50
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC;
