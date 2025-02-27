WITH RECURSIVE movie_recommendations AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(k.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(k.id) > 5
),
person_movies AS (
    SELECT 
        c.person_id,
        c.movie_id,
        p.info AS person_info,
        m.title AS movie_title,
        COALESCE(pn.name, 'Unknown') AS person_name
    FROM 
        cast_info c
    JOIN 
        aka_name pn ON c.person_id = pn.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    JOIN 
        person_info p ON c.person_id = p.person_id AND p.info_type_id = 1
),
top_movies AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title,
        rm.production_year,
        ROW_NUMBER() OVER (ORDER BY rm.keyword_count DESC) AS rank
    FROM 
        movie_recommendations rm
    WHERE 
        rm.production_year = (SELECT MAX(production_year) FROM movie_recommendations)
)
SELECT 
    pm.person_name,
    tm.movie_title,
    pm.person_info,
    CASE 
        WHEN tm.rank <= 10 THEN 'Top Recommendation'
        ELSE 'Standard Recommendation'
    END AS recommendation_type,
    COUNT(DISTINCT mct.kind) AS company_types_count,
    STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.country_code IS NOT NULL) AS production_companies,
    (SELECT COUNT(*) FROM movie_companies WHERE movie_id = tm.movie_id) AS total_companies
FROM 
    person_movies pm
JOIN 
    top_movies tm ON pm.movie_id = tm.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = pm.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type mct ON mc.company_type_id = mct.id
WHERE 
    pm.person_info IS NOT NULL
GROUP BY 
    pm.person_name, tm.movie_title, pm.person_info, tm.rank
HAVING 
    COUNT(DISTINCT mct.kind) > 1 OR COUNT(DISTINCT cn.id IS NULL) = 0
ORDER BY 
    tm.rank, pm.person_name;
