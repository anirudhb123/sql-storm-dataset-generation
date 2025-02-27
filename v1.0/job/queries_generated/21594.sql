WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list,
        COUNT(ci.person_id) AS actor_count,
        AVG(CASE 
                WHEN ci.note IS NULL THEN 0 
                ELSE LENGTH(ci.note) 
            END) AS avg_note_length
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.note IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.actors_list,
    cd.actor_count,
    ci.production_companies,
    rm.total_movies,
    CASE 
        WHEN cd.actor_count = 0 THEN 'No actors' 
        ELSE 'Has actors' 
    END AS actor_status,
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = rm.movie_id 
        AND mi.info_type_id IN (
            SELECT it.id 
            FROM info_type it 
            WHERE it.info ILIKE '%critics%'
        )
    ) AS has_critics_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rn = 1 -- Only get the movie with the highest alphabetical title for each year
ORDER BY 
    rm.production_year, rm.title;

-- Additional validations for corner cases
SELECT 
    COUNT(*) AS movies_without_production_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    ci.production_companies IS NULL;

SELECT 
    COUNT(DISTINCT rm.movie_id) FILTER (WHERE cd.actor_count = 0) AS movies_with_no_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id;

-- Join with an outer join to verify NULL handling with possible keyword association
SELECT 
    rm.title,
    k.keyword,
    COALESCE(k.keyword, 'No keyword') AS keyword_status
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.title;


This SQL query contains various advanced constructs such as CTEs, window functions, string aggregation, NULL checks, and filters. It's designed to give insights into movies while handling some corner cases such as missing actor or production company data. The additional validation sections check for movies without associated production companies and count movies that have no actors, showcasing how to interactively address potential NULL scenarios.
