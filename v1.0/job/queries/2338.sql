WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        COUNT(DISTINCT kc.keyword) AS associated_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT a.id) AS num_actors,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_assigned
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
CombinedDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COALESCE(ad.num_actors, 0) AS num_actors,
        COALESCE(md.production_companies, 0) AS production_companies,
        COALESCE(md.associated_keywords, 0) AS associated_keywords,
        COALESCE(ad.avg_role_assigned, 0) AS avg_role_assigned
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorDetails ad ON md.movie_id = ad.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.num_actors,
    cd.production_companies,
    cd.associated_keywords,
    cd.avg_role_assigned,
    CASE 
        WHEN cd.num_actors > 0 THEN 'Has Actors' 
        ELSE 'No Actors' 
    END AS actor_status,
    CONCAT(cd.title, ' - ', cd.production_year) AS display_title
FROM 
    CombinedDetails cd
WHERE 
    cd.production_year >= 2000 
    AND cd.associated_keywords > 5
ORDER BY 
    cd.production_year DESC, cd.num_actors DESC
LIMIT 100;
