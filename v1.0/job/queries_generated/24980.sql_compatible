
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 END), 0) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        (t.production_year IS NOT NULL AND t.production_year >= 2000) 
        OR (t.title LIKE '%Alien%' OR t.title LIKE '%Robot%')
    GROUP BY 
        t.id, t.title, t.production_year
),
popular_companies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS unique_companies
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.name IS NOT NULL 
        AND c.country_code IN ('USA', 'UK')
    GROUP BY 
        mc.movie_id
),
title_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    INNER JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.num_cast,
    pk.unique_companies,
    COALESCE(tk.keywords, 'No Keywords') AS movie_keywords,
    CASE 
        WHEN rm.num_cast > 10 THEN 'Star-Studded'
        WHEN rm.num_cast BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Few Cast Members'
    END AS cast_quality
FROM 
    ranked_movies rm
LEFT JOIN 
    popular_companies pk ON rm.movie_id = pk.movie_id
LEFT JOIN 
    title_keywords tk ON rm.movie_id = tk.movie_id
WHERE 
    rm.rank_within_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.num_cast DESC 
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;
