
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), selected_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.actor_count,
        rm.actors,
        rm.keywords
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5  
)
SELECT 
    sm.title,
    sm.production_year,
    kt.kind AS movie_kind,
    sm.actor_count,
    sm.actors,
    sm.keywords
FROM 
    selected_movies sm
JOIN 
    kind_type kt ON sm.kind_id = kt.id
ORDER BY 
    sm.actor_count DESC, sm.production_year DESC;
