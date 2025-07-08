
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rn
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TitleWithActors AS (
    SELECT 
        at.title,
        p.name,
        COUNT(ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        at.title, p.name
),
FilteredTitles AS (
    SELECT 
        rt.title,
        md.company_count,
        tla.actor_count,
        tla.has_note
    FROM 
        RankedTitles rt
    JOIN 
        MovieDetails md ON rt.title_id = md.movie_id
    JOIN 
        TitleWithActors tla ON rt.title = tla.title
    WHERE 
        rt.rn <= 5 AND 
        (md.company_count > 0 OR tla.has_note > 0)
)

SELECT 
    ft.title,
    ft.company_count,
    ft.actor_count
FROM 
    FilteredTitles ft
ORDER BY 
    ft.actor_count DESC, ft.company_count ASC;
