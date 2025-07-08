
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ct.kind AS company_type,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, ct.kind
), RankedMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year, 
        movie_keyword, 
        company_name,
        company_type,
        actor_names, 
        DENSE_RANK() OVER (PARTITION BY movie_keyword ORDER BY production_year DESC) AS rank
    FROM 
        MovieDetails 
)
SELECT 
    title_id,
    title,
    production_year,
    movie_keyword,
    company_name,
    company_type,
    actor_names
FROM 
    RankedMovies
WHERE 
    rank <= 3
ORDER BY 
    movie_keyword, production_year DESC;
