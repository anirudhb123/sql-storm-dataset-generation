WITH 
-- CTE to gather average roles per person_id
average_roles AS (
    SELECT 
        ci.person_id,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),

-- CTE to get titles of movies produced in the last 10 years with non-null production_year
recent_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        aka_title at ON at.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
    GROUP BY 
        t.id
)

SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    STRING_AGG(DISTINCT rm.title ORDER BY rm.production_year DESC) AS titles,
    ar.avg_roles,
    rc.*,
    COALESCE(NULLIF(SUM(mk.keywords), 0), 'No Keywords') AS keywords_summary,
    CASE 
        WHEN COUNT(DISTINCT ci.movie_id) > ar.avg_roles
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS role_performance,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_ranking
FROM 
    aka_name p
JOIN 
    cast_info ci ON ci.person_id = p.person_id
LEFT JOIN 
    recent_movies rm ON rm.title_id = ci.movie_id
LEFT JOIN 
    average_roles ar ON ar.person_id = ci.person_id
LEFT JOIN 
    (SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
     FROM
        movie_keyword mk
     JOIN
        keyword k ON mk.keyword_id = k.id
     GROUP BY 
        mk.movie_id
    ) AS mk ON mk.movie_id = ci.movie_id
LEFT JOIN 
    info_type it ON it.id = (SELECT MIN(info_type_id) FROM person_info pi WHERE pi.person_id = p.person_id) -- getting info_type_id to join (correlated subquery)
WHERE 
    ci.nr_order IS NOT NULL
    AND (ar.avg_roles IS NULL OR ar.avg_roles > 0) -- handling NULL logic
GROUP BY 
    p.id, ar.avg_roles, rc
HAVING 
    COUNT(DISTINCT ci.movie_id) > 3 -- requiring more than 3 movies
ORDER BY 
    role_performance DESC, actor_ranking;
