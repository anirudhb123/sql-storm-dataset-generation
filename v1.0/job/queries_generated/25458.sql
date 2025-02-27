WITH movie_title_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 -- focusing on recent movies
),

actor_info AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        COUNT(c.id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name, c.movie_id
    HAVING 
        COUNT(c.id) > 1 -- only actors with multiple roles in a movie
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
    mti.title AS movie_title,
    mti.production_year,
    ai.actor_name,
    ai.role_count AS number_of_roles,
    ci.company_name,
    ci.company_type
FROM 
    movie_title_info mti
JOIN 
    actor_info ai ON mti.movie_id = ai.movie_id
JOIN 
    company_info ci ON mti.movie_id = ci.movie_id
ORDER BY 
    mti.production_year DESC, 
    ai.role_count DESC, 
    mti.title;
