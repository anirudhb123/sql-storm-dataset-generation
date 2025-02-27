WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        t.id, 
        t.title, 
        t.production_year
    FROM 
        title t
    INNER JOIN 
        RankedTitles rt ON t.title = rt.title
    WHERE 
        rt.title_rank <= 5
),
MovieDetails AS (
    SELECT 
        ft.id AS movie_id,
        ft.title,
        COALESCE(mi.info, 'No information') AS info,
        CASE 
            WHEN mi.info IS NOT NULL THEN 'Provided'
            ELSE 'Missing'
        END AS info_status
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        movie_info mi ON ft.id = mi.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    md.info AS Movie_Info,
    md.info_status,
    COALESCE(ar.actor_count, 0) AS Actor_Count,
    ar.actors AS Actor_Names
FROM 
    MovieDetails md
LEFT JOIN 
    ActorRoles ar ON md.movie_id = ar.movie_id
ORDER BY 
    md.production_year DESC, md.title ASC;
