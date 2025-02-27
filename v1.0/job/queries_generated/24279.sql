WITH movie_ranked AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        movie_ranked
    WHERE 
        rn <= 5
),
linked_movies AS (
    SELECT 
        ml.movie_id,
        mt.title AS linked_title,
        ml.linked_movie_id,
        ml.link_type_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    WHERE 
        mt.production_year BETWEEN (SELECT MIN(production_year) FROM top_movies) AND (SELECT MAX(production_year) FROM top_movies)
),
companies_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title AS top_movie_title,
    tm.production_year,
    COALESCE(lm.linked_title, 'No linked movie') AS linked_movie_title,
    ci.company_names,
    ci.company_count,
    (CASE 
        WHEN ci.company_count > 0 THEN 'Yes' 
        ELSE 'No' 
    END) AS has_companies,
    (CASE 
        WHEN tm.cast_count IS NULL THEN 'Unknown' 
        ELSE CAST(tm.cast_count AS TEXT) 
    END) AS cast_count_text
FROM 
    top_movies tm
LEFT JOIN 
    linked_movies lm ON tm.title = lm.linked_title
LEFT JOIN 
    companies_info ci ON tm.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
WHERE 
    (tm.cast_count > 0 OR lm.linked_title IS NOT NULL)
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;

-- Additional complexity with NULL handling and obscure predicates
WITH filtered_companies AS (
    SELECT 
        DISTINCT cn.id, 
        cn.name,
        CASE 
            WHEN cn.country_code IS NULL THEN 'Unknown' 
            ELSE cn.country_code 
        END AS country_code
    FROM 
        company_name cn 
    WHERE 
        cn.name NOT LIKE '%Inc%'
)
SELECT 
    movie.title,
    mc.company_count,
    fc.country_code
FROM 
    aka_title movie 
LEFT JOIN 
    movie_companies mc ON movie.movie_id = mc.movie_id
LEFT JOIN 
    filtered_companies fc ON mc.company_id = fc.id 
WHERE 
    fc.country_code IS NOT NULL OR mc.company_id IS NULL
ORDER BY 
    movie.production_year;
