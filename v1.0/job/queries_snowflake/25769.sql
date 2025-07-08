WITH ranked_cast AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ci.note AS role_note,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) as actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
company_movies AS (
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
),
aggregated_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT km.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cm.company_name) AS companies,
        ARRAY_AGG(DISTINCT cm.company_type) AS company_types
    FROM 
        aka_title t
    LEFT JOIN 
        keyword_movies km ON t.id = km.movie_id
    LEFT JOIN 
        company_movies cm ON t.id = cm.movie_id
    GROUP BY 
        t.id, t.title
)

SELECT 
    rc.actor_name,
    rc.movie_title,
    rc.production_year,
    rc.role_note,
    ai.keywords,
    ai.companies,
    ai.company_types
FROM 
    ranked_cast rc
JOIN 
    aggregated_info ai ON rc.movie_title = ai.title
WHERE 
    rc.actor_rank = 1
ORDER BY 
    rc.production_year DESC, rc.actor_name;
