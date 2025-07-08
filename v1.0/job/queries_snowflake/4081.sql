
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS cast_with_roles
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        cc.movie_id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_data AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        cs.total_cast,
        cs.cast_with_roles,
        ki.keywords,
        mt.rank
    FROM 
        ranked_titles mt
    LEFT JOIN 
        cast_summary cs ON mt.title_id = cs.movie_id
    LEFT JOIN 
        keyword_info ki ON mt.title_id = ki.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.total_cast, 0) AS total_cast,
    COALESCE(md.cast_with_roles, 0) AS cast_with_roles,
    COALESCE(md.keywords, 'No keywords') AS keywords
FROM 
    movie_data md
WHERE 
    md.rank <= 5
ORDER BY 
    md.production_year DESC, md.total_cast DESC
LIMIT 10;
