WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
AggregateDetails AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        STRING_AGG(ad.actor_name || ' (' || ad.role_name || ')', ', ') AS actors,
        COUNT(DISTINCT md.keyword) AS keyword_count,
        MAX(md.keyword_rank) AS highest_keyword_rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorDetails ad ON md.title_id = ad.movie_id
    GROUP BY 
        md.title_id, md.title, md.production_year
)
SELECT 
    ad.title,
    ad.production_year,
    COALESCE(ad.actors, 'No actors available') AS actors,
    CASE 
        WHEN ad.keyword_count > 2 THEN 'Diverse Keywords'
        WHEN ad.keyword_count = 0 THEN 'No Keywords'
        ELSE 'Limited Keywords'
    END AS keyword_description,
    MAX(ad.highest_keyword_rank) AS max_keyword_rank
FROM 
    AggregateDetails ad
WHERE 
    ad.production_year >= 2000
    AND ad.production_year < 2024
ORDER BY 
    ad.production_year DESC, ad.title;
