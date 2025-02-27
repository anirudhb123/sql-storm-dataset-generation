WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.actor_count,
        COALESCE(NULLIF(c.name, ''), 'Unknown') AS company_name,
        STRING_AGG(DISTINCT m_info.info, ', ') AS movie_info
    FROM 
        aka_title t
    LEFT JOIN 
        ActorCount a ON t.id = a.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info m_info ON t.id = m_info.movie_id
    GROUP BY 
        t.id, a.actor_count, c.name
),
FilteredMovies AS (
    SELECT 
        md.*,
        CASE 
            WHEN md.actor_count >= 5 THEN 'Blockbuster'
            WHEN md.actor_count BETWEEN 3 AND 4 THEN 'Moderate'
            ELSE 'Indie'
        END AS movie_category
    FROM 
        MovieDetails md
    WHERE 
        md.production_year BETWEEN 2000 AND 2020
),
FinalOutput AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS production_year_rank
    FROM 
        FilteredMovies
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.movie_category,
    f.company_name,
    f.movie_info,
    COALESCE(f.production_year_rank, 0) AS rank
FROM 
    FinalOutput f
WHERE 
    f.movie_category = 'Blockbuster'
ORDER BY 
    f.production_year DESC, f.actor_count DESC
LIMIT 10;
