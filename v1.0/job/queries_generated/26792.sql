WITH movie_actor_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        c.nr_order AS role_order,
        t.id AS movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_genre_info AS (
    SELECT 
        t.id AS movie_id,
        k.keyword AS genre
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
movie_company_info AS (
    SELECT 
        t.id AS movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
combined_info AS (
    SELECT 
        mai.actor_name,
        mai.movie_title,
        mai.production_year,
        mai.actor_role,
        mai.role_order,
        mgi.genre,
        mci.company_name,
        mci.company_type
    FROM 
        movie_actor_info mai
    LEFT JOIN 
        movie_genre_info mgi ON mai.movie_id = mgi.movie_id
    LEFT JOIN 
        movie_company_info mci ON mai.movie_id = mci.movie_id
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    actor_role,
    role_order,
    STRING_AGG(DISTINCT genre, ', ') AS genres,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS production_companies
FROM 
    combined_info
GROUP BY 
    actor_name, movie_title, production_year, actor_role, role_order
ORDER BY 
    production_year DESC, actor_name;
