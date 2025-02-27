WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    mt.title,
    mt.production_year,
    a.actor_name,
    cs.company_name,
    cs.company_type,
    cs.num_movies,
    ARRAY_AGG(DISTINCT mt.keyword) AS keywords
FROM 
    MovieTitles mt
JOIN 
    ActorDetails a ON mt.title_id = a.movie_id
LEFT JOIN 
    CompanyStats cs ON mt.title_id = cs.movie_id
WHERE 
    mt.keyword IS NOT NULL
GROUP BY 
    mt.title, mt.production_year, a.actor_name, cs.company_name, cs.company_type, cs.num_movies
ORDER BY 
    mt.production_year DESC, mt.title;
