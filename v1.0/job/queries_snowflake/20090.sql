
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
cast_roles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info AS c
    GROUP BY 
        c.movie_id, c.role_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cr.role_count, 0) AS cast_role_count,
    COALESCE(ci.company_count, 0) AS company_count,
    ci.companies,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.title_rank < 5 THEN 'Top 5 title in year'
        ELSE 'Not in Top 5 title in year'
    END AS title_status
FROM 
    ranked_movies AS rm
LEFT JOIN 
    cast_roles AS cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    company_info AS ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    movie_keywords AS mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year > 2000
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cr.role_count, ci.company_count, ci.companies, mk.keywords, rm.title_rank
ORDER BY 
    rm.production_year DESC, 
    rm.title;
