WITH movie_actors AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    GROUP BY 
        ca.movie_id, a.name
), 
movie_details AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id,
        mk.keyword AS movie_keyword,
        COALESCE(ma.actor_count, 0) AS actor_count 
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        movie_actors ma ON ma.movie_id = t.id
), 
movie_ranking AS (
    SELECT 
        md.title,
        md.production_year,
        md.kind_id,
        md.movie_keyword,
        md.actor_count,
        RANK() OVER (PARTITION BY md.kind_id ORDER BY md.actor_count DESC) AS rank
    FROM 
        movie_details md 
    WHERE 
        md.actor_count > 0 
)
SELECT 
    mr.title, 
    mr.production_year, 
    kt.kind AS genre,
    mr.actor_count,
    mr.rank
FROM 
    movie_ranking mr
JOIN 
    kind_type kt ON mr.kind_id = kt.id
WHERE 
    mr.rank <= 5
ORDER BY 
    kt.kind, 
    mr.rank;

