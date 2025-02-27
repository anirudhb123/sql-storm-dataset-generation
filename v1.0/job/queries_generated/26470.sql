WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_type,
        k.keyword AS movie_keyword,
        STRING_AGG(mi.info, '; ') AS additional_info
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type AS c ON ci.person_role_id = c.id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info AS mi ON t.id = mi.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind, k.keyword
),
rating_summary AS (
    SELECT 
        md.movie_title,
        md.production_year,
        COUNT(*) AS actor_count,
        COUNT(DISTINCT md.movie_keyword) AS distinct_keywords,
        STRING_AGG(DISTINCT md.role_type, ', ') AS roles
    FROM 
        movie_details md
    GROUP BY 
        md.movie_title, md.production_year
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.actor_count,
    ms.distinct_keywords,
    ms.roles,
    CASE 
        WHEN ms.actor_count > 10 THEN 'Ensemble Cast'
        WHEN ms.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_category,
    COALESCE(md.additional_info, 'No Additional Info') AS additional_info
FROM 
    rating_summary ms
LEFT JOIN 
    movie_details md ON ms.movie_title = md.movie_title AND ms.production_year = md.production_year
ORDER BY 
    ms.production_year DESC, ms.actor_count DESC;
