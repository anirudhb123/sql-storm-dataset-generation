WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        p.name AS actor_name,
        0 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM title WHERE production_year > 2000)

    UNION ALL

    SELECT 
        ci.person_id,
        p.name AS actor_name,
        ah.level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ci ON ah.person_id = ci.person_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        ci.movie_id IN (SELECT linked_movie_id FROM movie_link WHERE link_type_id = 1)
),

LatestMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT an.name) AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year = (SELECT MAX(production_year) FROM title)
    GROUP BY 
        t.title, t.production_year
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    lm.title,
    lm.production_year,
    lm.actors,
    lm.keyword_count,
    cs.company_count,
    cs.company_names,
    CASE 
        WHEN lm.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity,
    COUNT(ah.actor_name) AS total_actors_in_series
FROM 
    LatestMovies lm
LEFT JOIN 
    CompanyStats cs ON lm.movie_id = cs.movie_id
LEFT JOIN 
    ActorHierarchy ah ON ah.level = 0 -- Counting only top-level actors
GROUP BY 
    lm.title, lm.production_year, lm.actors, lm.keyword_count, cs.company_count, cs.company_names
ORDER BY 
    lm.production_year DESC, lm.keyword_count DESC;
