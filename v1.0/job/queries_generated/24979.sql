WITH RECURSIVE movie_cast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS person_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_years AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(cast_order) AS max_cast_order
    FROM 
        title t
    LEFT JOIN 
        movie_cast c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
company_details AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc 
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mc.total_cast, 0) AS cast_count,
    COALESCE(cd.total_companies, 0) AS company_count,
    cd.company_names,
    CASE 
        WHEN mc.max_cast_order IS NULL THEN 'No cast';
        ELSE CONCAT('Cast order: ', mc.max_cast_order)
    END AS cast_info,
    CASE 
        WHEN mc.total_cast > 10 THEN 'Large Cast'
        WHEN mc.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    movie_years m
LEFT JOIN 
    movie_cast mc ON m.title_id = mc.movie_id
LEFT JOIN 
    company_details cd ON m.title_id = cd.movie_id
WHERE 
    m.production_year IS NOT NULL
    AND (m.production_year > 2000 OR m.title ILIKE '%Adventure%')
ORDER BY 
    m.production_year DESC,
    cast_count DESC
LIMIT 50;

This query fetches movie titles along with their productions years, total cast count, number of production companies, and a concatenated string of company names, while applying various complex SQL constructs such as CTEs, outer joins, conditional logic and string aggregation. Additionally, it uses conditional expressions to categorize the cast size while incorporating corner cases like titles without a cast or production information.
