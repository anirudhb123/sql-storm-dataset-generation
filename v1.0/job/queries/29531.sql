WITH RankedTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND t.title IS NOT NULL
),

TopActors AS (
    SELECT 
        actor_id, 
        actor_name, 
        movie_title, 
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
),

Info AS (
    SELECT 
        pa.person_id,
        pa.info AS actor_info,
        pt.info AS title_info,
        ka.keyword AS associated_keyword
    FROM 
        person_info pa
    LEFT JOIN 
        movie_info_idx pt ON pa.person_id = pt.movie_id
    LEFT JOIN 
        movie_keyword mk ON pt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ka ON mk.keyword_id = ka.id
)

SELECT 
    ta.actor_name,
    ta.movie_title,
    ta.production_year,
    COUNT(i.actor_info) AS info_count,
    STRING_AGG(DISTINCT i.associated_keyword, ', ') AS keywords
FROM 
    TopActors ta
LEFT JOIN 
    Info i ON ta.actor_id = i.person_id
GROUP BY 
    ta.actor_name, ta.movie_title, ta.production_year
ORDER BY 
    ta.production_year DESC, COUNT(i.actor_info) DESC;
