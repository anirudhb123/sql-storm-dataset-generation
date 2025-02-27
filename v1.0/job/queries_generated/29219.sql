WITH aggregated_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS num_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM aka_title a
    JOIN cast_info ca ON a.id = ca.movie_id
    JOIN aka_name ak ON ca.person_id = ak.person_id
    WHERE a.production_year >= 2000
    GROUP BY a.id, a.title, a.production_year
), movie_details AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        m.num_actors,
        m.actor_names,
        COALESCE(KW.keyword_list, 'No Keywords') AS keywords
    FROM aggregated_movies m
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keyword_list
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        GROUP BY mk.movie_id
    ) KW ON m.movie_id = KW.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.num_actors,
    md.actor_names,
    md.keywords
FROM movie_details md
ORDER BY md.production_year DESC, md.num_actors DESC
LIMIT 10;
