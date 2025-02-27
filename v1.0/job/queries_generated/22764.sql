WITH
-- CTE to fetch distinct movies with their corresponding year and title
movies_with_year AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(MIN(mci.id), 0) AS company_id -- using COALESCE to handle NULLs
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mci ON t.id = mci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year 
),

-- CTE to get the full list of actors with their latest role count per movie
latest_roles AS (
    SELECT 
        ci.movie_id AS movie_id,
        ci.person_id,
        COUNT(*) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order DESC) AS rn
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id, ci.person_id
),

-- CTE to select actors that played in at least 3 movies
actors_with_min_roles AS (
    SELECT 
        person_id,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        cast_info
    GROUP BY 
        person_id
    HAVING 
        COUNT(DISTINCT movie_id) >= 3
),

-- CTE to gather detailed info about movies related to the keywords
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords -- Collecting keywords into a string
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)

SELECT 
    m.title,
    m.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    r.role_count,
    CASE 
        WHEN r.role_count > 1 THEN 'Starring'
        ELSE 'Cameo'
    END AS role_type,
    m.company_id
FROM 
    movies_with_year m
LEFT JOIN 
    latest_roles r ON m.movie_id = r.movie_id AND r.rn = 1  -- getting the latest role
LEFT JOIN 
    aka_name a ON r.person_id = a.person_id
LEFT JOIN 
    movies_with_keywords kw ON m.movie_id = kw.movie_id
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM aka_title) 
    OR (m.production_year IS NULL AND a.name IS NOT NULL) -- considering NULL production years
ORDER BY 
    m.production_year DESC, 
    a.name
LIMIT 50;

-- Using a set operator to combine results across years that returned no actors
UNION ALL
SELECT 
    'N/A' AS title,
    year AS production_year,
    'No Actor Found' AS actor_name,
    'No Keywords' AS keywords,
    0 AS role_count,
    'N/A' AS role_type,
    0 AS company_id
FROM 
    (SELECT DISTINCT production_year AS year FROM aka_title) AS years
WHERE 
    year NOT IN (SELECT DISTINCT production_year FROM movies_with_year);
