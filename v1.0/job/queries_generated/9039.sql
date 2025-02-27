WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        COUNT(ci.id) AS actor_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name
), movie_keywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
), movie_companies AS (
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
    rm.title, 
    rm.production_year, 
    string_agg(DISTINCT rm.actor_name, ', ') AS actors, 
    COUNT(DISTINCT mk.keyword) AS keyword_count, 
    COUNT(DISTINCT mc.company_name) AS company_count
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.title = (SELECT title FROM title WHERE id = mk.movie_id)
LEFT JOIN 
    movie_companies mc ON rm.title = (SELECT title FROM title WHERE id = mc.movie_id)
GROUP BY 
    rm.title, 
    rm.production_year
ORDER BY 
    rm.production_year DESC, 
    rm.title;
