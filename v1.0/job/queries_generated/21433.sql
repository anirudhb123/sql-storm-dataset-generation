WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        mc.movie_id,
        c.person_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        c.nr_order IS NOT NULL
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword kw ON mt.keyword_id = kw.id
    GROUP BY 
        mt.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title AS production_title,
    rt.production_year,
    COALESCE(mw.keywords, 'No Keywords') AS keywords_found,
    COUNT(DISTINCT mc.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ci.company_name, '; ') AS production_companies
FROM 
    ranked_titles rt
LEFT JOIN 
    movie_cast mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    movies_with_keywords mw ON rt.title_id = mw.movie_id
LEFT JOIN 
    company_info ci ON rt.title_id = ci.movie_id
WHERE 
    rt.title_rank <= 5 
    AND rt.production_year > 2000
GROUP BY 
    rt.title, rt.production_year
HAVING 
    COUNT(DISTINCT mc.actor_name) > 2
ORDER BY 
    rt.production_year DESC, production_title
LIMIT 50;
