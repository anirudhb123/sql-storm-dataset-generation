WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        p.name AS actor_name,
        r.role
    FROM 
        aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%action%' 
),
AggregatedDetails AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
        STRING_AGG(DISTINCT actor_name || ' as ' || role, ', ') AS cast_details
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    production_companies,
    cast_details
FROM 
    AggregatedDetails
ORDER BY 
    production_year DESC, title;