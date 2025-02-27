WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_kind,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        comp_cast_type cct ON ci.person_role_id = cct.id
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind
),
TopRatedMovies AS (
    SELECT
        movie_title,
        production_year,
        actor_name,
        role_kind,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS ranking
    FROM
        MovieDetails
)
SELECT 
    production_year,
    movie_title,
    actor_name,
    role_kind,
    keywords
FROM 
    TopRatedMovies
WHERE 
    ranking <= 5
ORDER BY 
    production_year DESC;
