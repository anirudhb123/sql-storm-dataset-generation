WITH Recursive Titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(ct.kind, 'Unknown') AS kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_order
    FROM 
        title t
    LEFT JOIN 
        kind_type ct ON t.kind_id = ct.id
),
Actors AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        cast_info c
    INNER JOIN 
        aka_name ak ON c.person_id = ak.person_id
),
MoviesWithActors AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        tt.kind,
        COALESCE(a.actor_name, 'No actors') AS actor_name,
        a.actor_order
    FROM 
        Titles tt
    LEFT JOIN 
        Actors a ON tt.title_id = a.movie_id
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        kind,
        actor_name,
        actor_order
    FROM 
        MoviesWithActors
    WHERE 
        kind <> 'Documentary' 
        AND (production_year BETWEEN 1990 AND 2000)
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    f.kind,
    COUNT(f.actor_name) FILTER (WHERE f.actor_name != 'No actors') AS actor_count,
    STRING_AGG(f.actor_name, ', ') AS actor_list,
    COALESCE(f.actor_name, 'Absent Actor') AS actor_status,
    CASE 
        WHEN f.actor_count = 0 THEN 'No actors present'
        WHEN f.actor_count = 1 THEN 'Single actor present'
        ELSE 'Multiple actors present'
    END AS actor_summary
FROM 
    FilteredMovies f
GROUP BY 
    f.title_id, f.title, f.production_year, f.kind
ORDER BY 
    f.production_year DESC, 
    f.title ASC
LIMIT 50;
