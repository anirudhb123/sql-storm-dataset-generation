
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_cast AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        c.nr_order,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_companies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    ac.actor_name,
    ac.role_name,
    mk.keywords,
    mc.companies,
    mc.company_count,
    COALESCE(ac.nr_order, 0) AS order_in_cast,
    CASE 
        WHEN mc.company_count > 0 THEN 'Produced'
        ELSE 'Not Produced'
    END AS production_status
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_cast ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank_year <= 10 AND
    (ac.role_name IS NOT NULL OR mc.company_count > 0)
GROUP BY 
    rm.movie_title, 
    rm.production_year, 
    ac.actor_name, 
    ac.role_name, 
    mk.keywords, 
    mc.companies, 
    mc.company_count, 
    ac.nr_order
ORDER BY 
    rm.production_year DESC, 
    ac.nr_order;
