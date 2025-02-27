WITH movie_ratings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        AVG(CASE 
                WHEN pi.info_type_id = 1 THEN CAST(pi.info AS DECIMAL)
                ELSE NULL 
            END) AS average_rating,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
        LEFT JOIN movie_info mi ON t.movie_id = mi.movie_id
        LEFT JOIN person_info pi ON pi.info_type_id = mi.info_type_id
        LEFT JOIN cast_info ci ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title
),
company_movies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
        JOIN company_name c ON mc.company_id = c.id
        JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.average_rating,
    mr.cast_count,
    COALESCE(cm.company_name, 'Independent') AS company_name
FROM 
    movie_ratings mr
FULL OUTER JOIN company_movies cm ON mr.movie_id = cm.movie_id
WHERE 
    mr.average_rating IS NOT NULL 
    OR mr.cast_count > 0
ORDER BY 
    mr.average_rating DESC NULLS LAST, 
    mr.cast_count DESC,
    company_name ASC
FETCH FIRST 20 ROWS ONLY;

-- Further complexity: String expressions, unusual case handling
SELECT 
    title,
    CASE 
        WHEN average_rating IS NULL THEN 'No Rating'
        WHEN average_rating >= 8 THEN 'Highly Rated'
        WHEN average_rating >= 5 THEN 'Moderately Rated'
        ELSE 'Poorly Rated' 
    END AS rating_description,
    LENGTH(title) - LENGTH(REPLACE(title, ' ', '')) + 1 AS word_count,
    CASE 
        WHEN company_name LIKE '%Productions%' THEN 'Production Company'
        ELSE 'Other' 
    END AS company_category
FROM 
    movie_ratings
WHERE 
    word_count > 5;
