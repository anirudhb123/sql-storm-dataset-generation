WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title t
),
FilteredTitles AS (
    SELECT 
        rt.*,
        CASE 
            WHEN rt.title_count > 10 THEN 'Popular'
            WHEN rt.production_year = 2020 THEN 'Recent'
            ELSE 'Other'
        END AS title_category
    FROM 
        RankedTitles rt
    WHERE 
        rt.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithActors AS (
    SELECT 
        ft.*,
        am.actor_count
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        ActorMovies am ON ft.title_id = am.movie_id
),
JoinCounts AS (
    SELECT 
        m.title,
        COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        MoviesWithActors m
    LEFT JOIN 
        movie_companies mc ON m.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.title
)
SELECT 
    j.title,
    j.actor_count,
    j.company_count,
    j.companies,
    CASE
        WHEN j.actor_count > 5 AND j.company_count > 0 THEN 'Big Production'
        WHEN j.actor_count = 0 THEN 'No Actors'
        ELSE 'Independent'
    END AS production_type,
    COALESCE(NULLIF(j.companies, ''), 'Unknown Company') AS final_company_list
FROM 
    MoviesWithActors j
WHERE 
    j.title_category = 'Popular'
    OR (j.actor_count IS NULL AND j.company_count = 0)
ORDER BY 
    j.production_year DESC, 
    j.title;
