
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
CastDetails AS (
    SELECT 
        c.movie_id,
        c.person_id,
        a.name AS actor_name,
        r.role AS role,
        rn.rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        (SELECT 
             person_id, 
             ROW_NUMBER() OVER (ORDER BY person_id) AS rank 
         FROM 
             person_info) rn ON c.person_id = rn.person_id
),
SelectedMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        cd.actor_name,
        cd.role
    FROM 
        RankedTitles rt
    JOIN 
        CastDetails cd ON rt.title_id = cd.movie_id
    WHERE 
        rt.year_rank <= 5
)
SELECT 
    sm.title_id,
    sm.title,
    LISTAGG(sm.actor_name || ' as ' || sm.role, ', ') WITHIN GROUP (ORDER BY sm.actor_name) AS cast
FROM 
    SelectedMovies sm
GROUP BY 
    sm.title_id, sm.title
ORDER BY 
    sm.title;
