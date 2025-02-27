WITH actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        a.imdb_index AS actor_imdb_index,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name, a.imdb_index
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        kt.kind AS movie_kind,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        kind_type kt ON m.kind_id = kt.id
    GROUP BY 
        m.id, m.title, m.production_year, kt.kind
),
actor_movie_info AS (
    SELECT 
        ad.actor_id,
        ad.actor_name,
        ad.actor_imdb_index,
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_kind,
        md.keyword_count
    FROM 
        actor_details ad
    JOIN 
        cast_info ci ON ad.actor_id = ci.person_id
    JOIN 
        movie_details md ON ci.movie_id = md.movie_id
)
SELECT 
    ami.actor_id,
    ami.actor_name,
    ami.actor_imdb_index,
    ami.movie_id,
    ami.movie_title,
    ami.production_year,
    ami.movie_kind,
    ami.keyword_count
FROM 
    actor_movie_info ami
WHERE 
    ami.keyword_count > 0
ORDER BY 
    ami.production_year DESC, ami.actor_name ASC;
