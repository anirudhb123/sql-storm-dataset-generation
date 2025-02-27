WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        ca.person_id,
        tt.title,
        tt.production_year,
        RANK() OVER (PARTITION BY ca.person_id ORDER BY tt.production_year DESC) AS movie_rank
    FROM 
        cast_info ca
    JOIN 
        aka_title tt ON ca.movie_id = tt.id
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
complex_joins AS (
    SELECT 
        ck.keyword AS keyword_text,
        ti.title,
        ti.production_year,
        co.name AS company_name,
        co.country_code,
        ROW_NUMBER() OVER (PARTITION BY ti.id ORDER BY ck.keyword) AS keyword_order
    FROM 
        movie_keyword mk
    JOIN 
        keyword ck ON mk.keyword_id = ck.id
    JOIN 
        aka_title ti ON mk.movie_id = ti.id
    LEFT JOIN 
        movie_companies mc ON ti.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
)
SELECT 
    ra.title_id,
    ra.title,
    ra.production_year,
    rc.company_name,
    kc.keyword_text,
    COUNT(DISTINCT am.person_id) AS actor_count,
    SUM(CASE WHEN am.movie_rank <= 3 THEN 1 ELSE 0 END) AS top_actor_movies,
    (SELECT COUNT(*) FROM keyword_counts WHERE movie_id = ra.title_id) AS associated_keywords,
    CASE 
        WHEN ra.total_titles > 10 THEN 'Popular Year'
        ELSE 'Less Popular Year'
    END AS year_popularity
FROM 
    ranked_titles ra
LEFT JOIN 
    actor_movies am ON ra.title_id = am.title_id
LEFT JOIN 
    complex_joins kc ON ra.title = kc.title AND ra.production_year = kc.production_year
LEFT JOIN 
    (SELECT DISTINCT movie_id, company_name FROM movie_companies mc 
     JOIN company_name co ON mc.company_id = co.id) rc ON ra.title_id = rc.movie_id
WHERE 
    ra.title_id IS NOT NULL
GROUP BY 
    ra.title_id, ra.title, ra.production_year, rc.company_name, kc.keyword_text, ra.total_titles
HAVING 
    COUNT(DISTINCT am.person_id) > 1
ORDER BY 
    ra.production_year DESC, actor_count DESC, ra.title;
