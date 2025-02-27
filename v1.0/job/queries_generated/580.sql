WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        COALESCE(c.name, 'Unknown') AS company_name
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year > 2000
), 
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
), 
ActorsByTitle AS (
    SELECT 
        md.movie_id,
        STRING_AGG(ai.actor_name, ', ') AS actors,
        COUNT(ai.actor_name) AS actor_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorInfo ai ON md.movie_id = ai.movie_id 
    GROUP BY 
        md.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    mt.movie_keyword,
    mt.company_name,
    abt.actors,
    abt.actor_count
FROM 
    MovieDetails mt
LEFT JOIN 
    ActorsByTitle abt ON mt.movie_id = abt.movie_id
WHERE 
    (mt.production_year = 2023 OR mt.production_year IS NULL)
    AND (abt.actor_count > 0 OR abt.actor_count IS NULL)
ORDER BY 
    mt.production_year DESC,
    abt.actor_count DESC;
