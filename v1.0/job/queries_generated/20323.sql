WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorsWithRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    JOIN 
        role_type r ON c.role_id = r.id
),

MoviesWithCompanyInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
),

SeasonalEpisodes AS (
    SELECT 
        title.id AS episode_id,
        title.title AS episode_title,
        title.season_nr,
        title.episode_nr,
        COALESCE(rt.role, 'Unknown') AS role_in_episode
    FROM 
        title
    LEFT JOIN 
        role_type rt ON title.kind_id = rt.id 
    WHERE 
        title.season_nr IS NOT NULL
)

SELECT 
    rm.movie_id,
    rm.title AS movie_title,
    rm.production_year,
    awr.actor_name,
    awr.role,
    mwc.companies,
    mwc.company_types,
    se.episode_title,
    se.season_nr,
    se.episode_nr,
    se.role_in_episode
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsWithRoles awr ON rm.movie_id = awr.movie_id
LEFT JOIN 
    MoviesWithCompanyInfo mwc ON rm.movie_id = mwc.movie_id
LEFT JOIN 
    SeasonalEpisodes se ON rm.movie_id = se.episode_of_id
WHERE 
    (rm.rank_per_year <= 3 AND awr.role_rank <= 2) OR 
    (rm.production_year IS NULL) OR 
    (mwc.companies IS NOT NULL AND se.season_nr IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title, 
    awr.actor_name;
