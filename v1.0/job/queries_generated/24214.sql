WITH RecursiveMovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ci.note, '; ') AS notes
    FROM 
        RecursiveMovieTitles mt
    LEFT JOIN 
        cast_info ci ON mt.title_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id 
    WHERE 
        ak.name IS NOT NULL 
    GROUP BY 
        mt.title_id, mt.title, mt.production_year
),
RankedMovies AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.actor_count,
        RANK() OVER (ORDER BY fm.actor_count DESC, fm.production_year DESC) AS rank
    FROM 
        FilteredMovies fm
    WHERE 
        fm.actor_count >= (SELECT AVG(actor_count) FROM FilteredMovies)
),
FinalOutput AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        COALESCE(rm.rank, 'Not Ranked') AS rank,
        CASE 
            WHEN rm.actor_count IS NULL THEN 'No actors'
            WHEN rm.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS era
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    fo.title,
    fo.production_year,
    fo.actor_count,
    fo.rank,
    fo.era
FROM 
    FinalOutput fo
ORDER BY 
    fo.rank, fo.production_year DESC;

-- Additionally checking for unusual NULL cases in movie titles and actors
SELECT 
    t.title,
    a.name,
    CASE 
        WHEN a.name IS NULL AND t.title IS NOT NULL THEN 'Orphaned Title'
        WHEN a.name IS NOT NULL AND t.title IS NULL THEN 'Orphaned Actor'
        ELSE 'Connected'
    END AS orphan_status
FROM 
    title t
FULL OUTER JOIN 
    aka_name a ON t.id = a.person_id
WHERE 
    t.title IS NULL OR a.name IS NULL;

-- Mark actors with bizarre roles expressed through note
SELECT 
    ci.note AS bizarre_role
FROM 
    cast_info ci
WHERE 
    ci.note LIKE '%bizarre%'
ORDER BY 
    ci.note;
