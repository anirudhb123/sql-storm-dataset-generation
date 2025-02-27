WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
)

SELECT 
    a.name AS actor_name,
    f.title AS movie_title,
    f.production_year,
    COALESCE(c.role_id, rt.title_id) AS role_type_id,
    COALESCE(c.note, 'N/A') AS role_note
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    FilteredTitles f ON cc.movie_id = f.title_id
ORDER BY 
    a.name, f.production_year DESC;
