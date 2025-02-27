
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN CHAR_LENGTH(a.name) > 0 THEN 1 ELSE 0 END) AS avg_name_length,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.movie_id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        aka_title m ON mc.movie_id = m.id
    WHERE 
        c.country_code IS NOT NULL OR ct.kind IS NOT NULL
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS unique_keywords,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    t.title,
    t.production_year,
    CAST(total_cast AS INTEGER) AS number_of_cast,
    COALESCE(avg_name_length, 0) AS average_name_length,
    COALESCE(company_name, 'N/A') AS producing_company,
    COALESCE(company_type, 'Unknown') AS kind_of_company,
    COALESCE(unique_keywords, 0) AS number_of_unique_keywords,
    COALESCE(keyword_list, 'None') AS keywords
FROM 
    ranked_titles t
LEFT JOIN 
    cast_details cd ON t.title_id = cd.movie_id
LEFT JOIN 
    company_info ci ON t.title_id = ci.movie_id
LEFT JOIN 
    keyword_stats ks ON t.title_id = ks.movie_id
WHERE 
    (t.kind_id IS NOT NULL AND t.production_year > 2000)
    OR (t.production_year IS NULL AND t.title LIKE '%')
ORDER BY 
    t.production_year DESC, title_rank
LIMIT 100;
