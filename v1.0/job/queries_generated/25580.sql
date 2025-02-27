WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS actor_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.actor_count > 5
),
AkaNames AS (
    SELECT 
        a.person_id,
        a.name,
        a.id
    FROM 
        aka_name a
    WHERE 
        a.name ILIKE '%Smith%'
),
SelectedMovies AS (
    SELECT 
        ft.title_id,
        ft.title,
        ft.production_year
    FROM 
        FilteredTitles ft
    JOIN 
        movie_info mi ON ft.title_id = mi.movie_id
    WHERE 
        mi.info ILIKE '%award%'
)
SELECT 
    sm.title,
    sm.production_year,
    an.name AS actor_name,
    COUNT(DISTINCT mi.info_type_id) AS info_type_count
FROM 
    SelectedMovies sm
JOIN 
    cast_info ci ON sm.title_id = ci.movie_id
JOIN 
    AkaNames an ON ci.person_id = an.person_id
JOIN 
    movie_info mi ON sm.title_id = mi.movie_id
GROUP BY 
    sm.title, sm.production_year, an.name
ORDER BY 
    sm.production_year DESC, actor_name;
