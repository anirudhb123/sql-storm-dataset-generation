WITH movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ki.keyword) AS total_keywords,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keyword_list,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE m.production_year >= 2000  
    GROUP BY m.id, m.title, m.production_year
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_list
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
),

complete_summary AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        m.total_keywords,
        m.keyword_list,
        m.companies,
        COALESCE(c.total_cast_members, 0) AS total_cast_members,
        COALESCE(c.cast_list, 'No cast available') AS cast_list
    FROM movie_info_summary m
    LEFT JOIN cast_summary c ON m.movie_id = c.movie_id
)

SELECT 
    cs.movie_title, 
    cs.production_year, 
    cs.total_keywords, 
    cs.keyword_list, 
    cs.total_cast_members, 
    cs.cast_list,
    cs.companies
FROM complete_summary cs
WHERE cs.total_cast_members > 0     
ORDER BY cs.production_year DESC, cs.movie_title;