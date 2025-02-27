WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.note, 'No Note') AS note,
        ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS year_rank
    FROM
        aka_title mt 
    WHERE 
        mt.production_year IS NOT NULL AND mt.title IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.note
    FROM 
        RecursiveMovieCTE m
    WHERE 
        m.year_rank <= 5
),
ActorsWithRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_name,
        ci.nr_order,
        ci.movie_id
    FROM 
        cast_info ci 
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),
AggregatedActors AS (
    SELECT 
        awr.movie_id,
        STRING_AGG(DISTINCT awr.actor_name, ', ') AS actors,
        COUNT(DISTINCT awr.role_name) AS role_count
    FROM 
        ActorsWithRoles awr
    GROUP BY 
        awr.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.note,
    COALESCE(aa.actors, 'No Actors') AS actor_list,
    aa.role_count,
    CASE 
        WHEN fm.production_year < 2000 THEN 'Classic'
        WHEN fm.production_year BETWEEN 2000 AND 2020 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    AggregatedActors aa ON fm.movie_id = aa.movie_id
WHERE 
    (aa.role_count IS NULL OR aa.role_count > 0)
    AND (fm.note LIKE '%Action%' OR fm.note IS NULL)
ORDER BY 
    fm.production_year DESC,
    era_category,
    aa.role_count DESC;
