
WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_companies
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
ActorDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT ci.person_role_id) AS roles_count
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name, ak.id
),
RankedActors AS (
    SELECT 
        ad.movie_id,
        ad.actor_name,
        ad.roles_count,
        ROW_NUMBER() OVER (PARTITION BY ad.movie_id ORDER BY ad.roles_count DESC) AS actor_rank
    FROM 
        ActorDetails ad
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_count,
    md.companies,
    ra.actor_name,
    ra.roles_count,
    ra.actor_rank
FROM 
    MovieDetails md
LEFT JOIN 
    RankedActors ra ON md.movie_id = ra.movie_id
WHERE 
    md.company_count > 0 
    AND (ra.roles_count IS NULL OR ra.roles_count >= 1)
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC, 
    ra.actor_rank ASC
LIMIT 50;
