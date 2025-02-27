WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.role_id) AS cast_roles,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
), 
ranked_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_names,
        md.keywords,
        md.cast_count,
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank_by_cast
    FROM 
        movie_details md
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.company_names,
    rm.keywords,
    rm.cast_count,
    rm.rank_by_cast
FROM 
    ranked_movies rm
WHERE 
    rm.rank_by_cast <= 10
ORDER BY 
    rm.rank_by_cast ASC;
