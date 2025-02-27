
WITH ActorMovieDetails AS (
    SELECT 
        a.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        c.nr_order AS role_order
    FROM 
        aka_name a
        JOIN cast_info c ON a.person_id = c.person_id
        JOIN aka_title t ON c.movie_id = t.id
        JOIN role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year BETWEEN 2000 AND 2020
),
KeywordMovies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
        JOIN keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    amd.actor_name,
    amd.movie_title,
    amd.production_year,
    amd.actor_role,
    amd.role_order,
    km.keywords,
    cd.companies,
    cd.company_types
FROM 
    ActorMovieDetails amd
    LEFT JOIN KeywordMovies km ON amd.movie_id = km.movie_id
    LEFT JOIN CompanyDetails cd ON amd.movie_id = cd.movie_id
ORDER BY 
    amd.production_year DESC,
    amd.actor_name ASC,
    amd.role_order;
