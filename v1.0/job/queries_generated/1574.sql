WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kc ON kc.id = mk.keyword_id
    GROUP BY 
        t.id, kt.kind
),
ActorDetails AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON a.id = ca.person_id
    WHERE 
        ca.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%')
),
MovieStatistics AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.movie_kind,
        COALESCE(ad.actor_name, 'Unknown Actor') AS top_actor,
        md.keyword_count,
        md.companies,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = md.title_id) AS complete_cast_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorDetails ad ON ad.movie_id = md.title_id
    WHERE 
        md.production_year >= 2000
    ORDER BY 
        md.production_year DESC, md.title
)
SELECT 
    ms.title,
    ms.production_year,
    ms.movie_kind,
    STRING_AGG(ms.companies, ', ') AS aggregated_companies,
    ms.keyword_count,
    ms.top_actor,
    CASE
        WHEN ms.complete_cast_count IS NULL THEN 'Not Available'
        ELSE ms.complete_cast_count::text
    END AS complete_cast_info
FROM 
    MovieStatistics ms
GROUP BY 
    ms.title, ms.production_year, ms.movie_kind, ms.keyword_count, ms.top_actor, ms.complete_cast_count
HAVING 
    COUNT(ms.top_actor) > 1
ORDER BY 
    ms.production_year DESC, ms.title;
