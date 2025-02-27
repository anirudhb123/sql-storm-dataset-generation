WITH movie_related AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        CASE 
            WHEN a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') THEN 'Film'
            WHEN a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'tvSeries') THEN 'TV Series'
            ELSE 'Other'
        END AS movie_category
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
actor_roles AS (
    SELECT 
        n.name AS actor_name,
        a.title AS movie_title,
        r.role AS role_name,
        c.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    JOIN 
        aka_title a ON ci.movie_id = a.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
company_count AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT company_name) AS company_count
    FROM 
        movie_related
    GROUP BY 
        movie_title
),
keyword_count AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT movie_keyword) AS keyword_count
    FROM 
        movie_related
    GROUP BY 
        movie_title
)
SELECT 
    mr.movie_title,
    mr.production_year,
    mr.movie_category,
    ac.actor_name,
    ac.role_name,
    cc.company_count,
    kc.keyword_count
FROM 
    movie_related mr
JOIN 
    actor_roles ac ON mr.movie_title = ac.movie_title
JOIN 
    company_count cc ON mr.movie_title = cc.movie_title
JOIN 
    keyword_count kc ON mr.movie_title = kc.movie_title
ORDER BY 
    mr.production_year DESC, mr.movie_title, ac.nr_order;
