WITH RECURSIVE ActorHierarchy AS (
    SELECT c.movie_id, a.person_id, a.name, 1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.nr_order = 1
    
    UNION ALL
    
    SELECT c.movie_id, a.person_id, a.name, ah.level + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE c.nr_order > ah.level
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        m.company_name,
        m.note AS company_note,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.id) AS actor_rank
    FROM 
        title t
    LEFT JOIN movie_companies m ON t.id = m.movie_id
    LEFT JOIN company_name cn ON m.company_id = cn.id
    LEFT JOIN ActorHierarchy a ON t.id = a.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'series'))
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_name, 'Unknown Production Company') AS company_name,
    COUNT(DISTINCT ah.person_id) AS total_actors,
    mk.keywords,
    COUNT(mci.movie_id) AS total_movies,
    MAX(CASE WHEN ah.level = 1 THEN ah.name END) AS lead_actor,
    STRING_AGG(DISTINCT ah.name, ', ') AS all_actors
FROM 
    MovieDetails md
LEFT JOIN 
    ActorHierarchy ah ON md.movie_id = ah.movie_id
LEFT JOIN 
    MovieKeywords mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast mci ON md.movie_id = mci.movie_id
GROUP BY 
    md.title, md.production_year, md.company_name
ORDER BY 
    md.production_year DESC, total_actors DESC
LIMIT 100;
