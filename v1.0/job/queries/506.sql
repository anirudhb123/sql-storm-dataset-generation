WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM 
        aka_title t
    WHERE 
        NOT EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = t.id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'release date')
        )
        AND t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
MoviesWithCompanies AS (
    SELECT 
        m.movie_id,
        m.total_actors,
        m.actor_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        MovieCast m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, m.total_actors, m.actor_names
)
SELECT 
    rm.rank_title,
    rm.title,
    rm.production_year,
    COALESCE(mwc.total_actors, 0) AS actor_count,
    mwc.actor_names,
    CASE 
        WHEN mwc.total_companies IS NULL THEN 'No Companies'
        ELSE CAST(mwc.total_companies AS TEXT)
    END AS company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MoviesWithCompanies mwc ON rm.movie_id = mwc.movie_id
WHERE 
    rm.rank_title < 10 
ORDER BY 
    rm.production_year DESC, rm.rank_title;
