WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
ranked_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        keyword,
        total_cast,
        total_companies,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_by_cast
    FROM 
        movie_details
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keyword,
    COALESCE(rm.total_cast, 0) AS total_cast,
    COALESCE(rm.total_companies, 0) AS total_companies,
    CASE 
        WHEN rm.total_cast IS NULL THEN 'No cast information'
        WHEN rm.total_cast > 10 THEN 'Popular'
        ELSE 'Less popular'
    END AS popularity
FROM 
    ranked_movies rm
WHERE 
    rm.production_year IS NOT NULL 
    AND rm.rank_by_cast <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
