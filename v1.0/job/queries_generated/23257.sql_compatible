
WITH RecursiveActorRoles AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        ca.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS acting_order
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
), MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(string_agg(k.keyword, ', '), 'No Keywords') AS keywords,
        string_agg(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
), ActorMediocreCounts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        RecursiveActorRoles
    GROUP BY 
        movie_id
    HAVING 
        COUNT(DISTINCT actor_name) BETWEEN 1 AND 3
), ComprehensiveStats AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorMediocreCounts ac ON md.movie_id = ac.movie_id
)

SELECT 
    cs.movie_id,
    cs.title,
    cs.production_year,
    cs.keywords,
    cs.actor_count,
    CASE 
        WHEN cs.actor_count = 0 THEN 'No Cast'
        WHEN cs.actor_count BETWEEN 1 AND 3 THEN 'Mediocre Cast'
        ELSE 'Strong Cast'
    END AS cast_quality
FROM 
    ComprehensiveStats cs
WHERE 
    cs.keywords LIKE '%Drama%'
ORDER BY 
    cs.production_year DESC,
    cs.actor_count ASC NULLS LAST;
