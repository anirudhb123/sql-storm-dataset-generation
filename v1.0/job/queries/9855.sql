WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ki.keyword) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ki.keyword) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        t.id, t.title, t.production_year
), actor_movies AS (
    SELECT 
        ak.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY t.production_year DESC) AS role_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
), company_details AS (
    SELECT 
        cn.name AS company_name,
        mc.movie_id,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title t ON mc.movie_id = t.id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.keyword_count,
    am.actor_name,
    cm.company_name,
    cm.company_type
FROM 
    ranked_movies rm
JOIN 
    actor_movies am ON rm.movie_id = am.movie_id AND am.role_rank <= 3
JOIN 
    company_details cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.keyword_count DESC, rm.production_year DESC;
