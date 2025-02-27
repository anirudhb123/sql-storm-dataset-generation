WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_name AS (
    SELECT 
        a.person_id,
        a.name,
        a.id AS aka_id,
        COALESCE(cn.name, 'Unknown') AS company_name
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
),
movie_keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
exclude_titles AS (
    SELECT 
        DISTINCT t.title 
    FROM 
        title t
    WHERE 
        t.title LIKE '%untitled%'
)

SELECT 
    rt.title,
    rt.production_year,
    an.name AS actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = rt.title_id AND cc.status_id IS NULL) AS unverified_cast_members
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_name an ON rt.title_id = an.person_id 
LEFT JOIN 
    movie_keyword_summary mk ON rt.title_id = mk.movie_id 
LEFT JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id 
WHERE 
    rt.year_rank < 5 
    AND rt.title NOT IN (SELECT title FROM exclude_titles)
GROUP BY 
    rt.title, rt.production_year, an.name, mk.keywords
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    rt.production_year DESC, rt.title
LIMIT 10;
