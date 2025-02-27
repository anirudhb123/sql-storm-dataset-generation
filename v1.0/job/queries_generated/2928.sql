WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t 
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
), keyword_count AS (
    SELECT 
        m.movie_id, 
        COUNT(k.id) AS keyword_count 
    FROM 
        movie_keyword m 
    JOIN 
        keyword k ON m.keyword_id = k.id 
    GROUP BY 
        m.movie_id
), actor_roles AS (
    SELECT 
        c.movie_id, 
        r.role,
        COUNT(DISTINCT c.person_id) AS role_count
    FROM 
        cast_info c 
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), movie_company_info AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS companies
    FROM 
        movie_companies mc 
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_actors,
    k.keyword_count,
    GROUP_CONCAT(DISTINCT ar.role) AS roles,
    mci.companies 
FROM 
    ranked_movies rm 
LEFT JOIN 
    keyword_count k ON rm.title = (SELECT title FROM title WHERE id = k.movie_id LIMIT 1)
LEFT JOIN 
    actor_roles ar ON rm.title = (SELECT title FROM title WHERE id = ar.movie_id LIMIT 1)
LEFT JOIN 
    movie_company_info mci ON rm.title = (SELECT title FROM title WHERE id = mci.movie_id LIMIT 1)
WHERE 
    rm.rank <= 5 
    AND rm.production_year IS NOT NULL
GROUP BY 
    rm.title, rm.production_year, rm.num_actors, k.keyword_count, mci.companies
ORDER BY 
    rm.production_year DESC, rm.num_actors DESC;
