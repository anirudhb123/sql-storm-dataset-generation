WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.imdb_index,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(*) DESC) AS actor_count_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.imdb_index
),
ActorDetails AS (
    SELECT 
        p.name AS actor_name,
        p.id AS person_id,
        r.role AS actor_role,
        m.movie_id,
        m.movie_title,
        m.production_year
    FROM 
        RankedMovies m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.actor_count_rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ad.movie_id,
    ad.movie_title,
    ad.production_year,
    ad.actor_name,
    ad.actor_role,
    cd.company_names,
    cd.company_types
FROM 
    ActorDetails ad
JOIN 
    CompanyDetails cd ON ad.movie_id = cd.movie_id
ORDER BY 
    ad.production_year DESC, ad.movie_title, ad.actor_name;
