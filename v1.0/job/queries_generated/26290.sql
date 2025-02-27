WITH MovieTitles AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),

ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        p.info AS actor_info,
        a.id AS actor_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
),

Filmography AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        a.actor_name,
        a.actor_info,
        m.production_year
    FROM 
        MovieTitles m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    JOIN 
        ActorDetails a ON ci.person_id = a.actor_id
),

ProductionCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    f.movie_title,
    f.production_year,
    f.actor_name,
    f.actor_info,
    GROUP_CONCAT(DISTINCT pc.company_name || ' (' || pc.company_type || ')') AS production_companies,
    GROUP_CONCAT(DISTINCT f.movie_keyword) AS keywords
FROM 
    Filmography f
LEFT JOIN 
    ProductionCompanies pc ON f.movie_id = pc.movie_id
GROUP BY 
    f.movie_title, f.production_year, f.actor_name, f.actor_info
ORDER BY 
    f.production_year DESC, f.movie_title;
