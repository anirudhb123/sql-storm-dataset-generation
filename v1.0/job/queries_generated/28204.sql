WITH MovieTitleInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        comp.name AS company_name,
        rt.role AS person_role,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name comp ON mc.company_id = comp.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 AND
        k.keyword LIKE '%action%'
),
AggregateInfo AS (
    SELECT 
        movie_id,
        movie_title,
        COUNT(actor_name) AS actor_count,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors_list,
        production_year,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MIN(company_name) AS production_company
    FROM 
        MovieTitleInfo
    GROUP BY 
        movie_id, movie_title, production_year
)

SELECT 
    movie_id,
    movie_title,
    actor_count,
    actors_list,
    production_year,
    keywords,
    production_company
FROM 
    AggregateInfo
ORDER BY 
    production_year DESC, actor_count DESC;
