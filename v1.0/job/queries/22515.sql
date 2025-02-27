
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), filtered_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        rank_by_cast,
        keyword,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank_by_cast = 1 AND 
        (cast_count > 5 OR (keyword <> 'No Keyword' AND production_year <= 2000))
), company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), final_results AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.keyword,
        COALESCE(ci.companies, 'No Companies') AS companies,
        COALESCE(ci.company_types, 'No Company Types') AS company_types,
        m.cast_count
    FROM 
        filtered_movies m
    LEFT JOIN 
        company_info ci ON m.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    companies, 
    company_types,
    CASE 
        WHEN production_year < 1980 THEN 'Classic'
        WHEN production_year BETWEEN 1980 AND 2000 THEN 'Modern Classic'
        ELSE 'Contemporary'
    END AS category,
    CASE 
        WHEN LENGTH(title) - LENGTH(REPLACE(title, ' ', '')) > 2 THEN 'Title has more than 2 words'
        ELSE 'Short Title'
    END AS title_length_info
FROM 
    final_results
WHERE 
    (companies IS NOT NULL OR company_types IS NOT NULL) AND 
    (keyword IS NOT NULL AND keyword <> '')
ORDER BY 
    production_year DESC, cast_count DESC;
