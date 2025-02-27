WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS rank
    FROM 
        title t
    JOIN 
        aka_title a ON t.id = a.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
),
ActorTitles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        t.title,
        t.production_year,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        title t ON ci.movie_id = t.id
)
SELECT 
    tt.title AS top_title,
    tt.production_year AS year,
    at.actor_name,
    at.actor_count,
    COALESCE(mt.note, 'No note available') AS note
FROM 
    TopTitles tt
LEFT JOIN 
    ActorTitles at ON tt.title_id = at.movie_id
LEFT JOIN 
    movie_info mi ON tt.title_id = mi.movie_id
LEFT JOIN 
    movie_info_idx mt ON tt.title_id = mt.movie_id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    tt.production_year >= 2000
ORDER BY 
    tt.production_year DESC,
    tt.title;
