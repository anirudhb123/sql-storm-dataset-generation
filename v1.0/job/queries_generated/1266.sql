WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(mci.note IS NOT NULL)::int, 0) AS company_count,
        COALESCE(SUM(DISTINCT mk.keyword IS NOT NULL)::int, 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
ActorsInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT p.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        md.company_count,
        md.keyword_count,
        COALESCE(ai.actor_count, 0) AS actor_count,
        COALESCE(ai.actor_names, 'No Actors') AS actor_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorsInfo ai ON md.movie_id = ai.movie_id
    WHERE 
        md.year_rank <= 5
)
SELECT 
    title,
    production_year,
    company_count,
    keyword_count,
    actor_count,
    actor_names
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, title;
