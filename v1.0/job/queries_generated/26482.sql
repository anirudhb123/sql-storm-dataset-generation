WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS keyword,
        ARRAY_AGG(DISTINCT a.name) AS aliases,
        ARRAY_AGG(DISTINCT c.name) AS cast_members,
        STRING_AGG(DISTINCT p.info, '; ') AS person_info
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
), detailed_report AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        keyword,
        ARRAY_TO_STRING(aliases, ', ') AS alias_list,
        ARRAY_TO_STRING(cast_members, ', ') AS cast_list,
        person_info 
    FROM 
        movie_details
)
SELECT 
    d.movie_id,
    d.movie_title,
    d.production_year,
    d.keyword,
    d.alias_list,
    d.cast_list,
    COUNT(*) OVER (PARTITION BY d.movie_id) AS total_cast_members,
    CASE 
        WHEN d.production_year < 2010 THEN 'Before 2010'
        ELSE '2010 or later'
    END AS production_period
FROM 
    detailed_report d
WHERE 
    d.keyword IS NOT NULL
ORDER BY 
    d.production_year DESC, d.movie_title;
