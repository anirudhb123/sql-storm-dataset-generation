WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (1, 2) -- Assuming 1: Movie, 2: TV Series
),
FilteredTitles AS (
    SELECT 
        rt.aka_id, 
        rt.person_id, 
        rt.name,
        rt.title_id, 
        rt.title, 
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_year <= 3
),
MaxYear AS (
    SELECT 
        person_id,
        MAX(production_year) AS max_year
    FROM 
        FilteredTitles
    GROUP BY 
        person_id
),
TitleWithMaxYear AS (
    SELECT 
        ft.*,
        my.max_year
    FROM 
        FilteredTitles ft
    JOIN 
        MaxYear my ON ft.person_id = my.person_id AND ft.production_year = my.max_year
),
Persona AS (
    SELECT 
        c.person_id,
        STRING_AGG(DISTINCT c.note, ', ') AS roles,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        cast_info ci
    JOIN 
        role_type c ON ci.role_id = c.id
    WHERE 
        c.role IS NOT NULL
    GROUP BY 
        c.person_id
),
CombiningResults AS (
    SELECT 
        tw.title,
        tw.production_year,
        p.roles,
        p.total_movies,
        COALESCE(tw.name, 'Unknown') AS actor_name,
        CASE 
            WHEN tw.production_year IS NULL THEN 'N/A'
            ELSE CAST(tw.production_year AS TEXT)
        END AS production_year_string
    FROM 
        TitleWithMaxYear tw
    LEFT JOIN 
        Persona p ON tw.person_id = p.person_id
)
SELECT 
    cr.title,
    cr.production_year,
    cr.roles,
    cr.total_movies,
    cr.actor_name,
    UPPER(cr.production_year_string) AS production_year_display
FROM 
    CombiningResults cr
WHERE 
    cr.total_movies > 5
ORDER BY 
    cr.production_year DESC, 
    cr.actor_name;

This query performs an elaborate selection process, starting with grabbing relevant titles associated with actors, filtering for the latest three titles only, and building a contextual view that incorporates movie roles and counts for actors. Additionally, it handles NULL cases and applies formatting through `CASE` and aggregation functions while ensuring that duplicates are managed appropriately through CTEs and window functions. Finally, results are filtered and sorted for meaningful output.
