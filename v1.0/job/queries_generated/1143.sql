WITH movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT cc.person_id) AS total_actors
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
actor_details AS (
    SELECT
        p.id AS person_id,
        p.name,
        COUNT(DISTINCT c.movie_id) AS acted_movies,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
    FROM
        aka_name p
    JOIN 
        cast_info c ON p.person_id = c.person_id
    GROUP BY 
        p.id, p.name
),
highest_rated AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Ratings') AS rating
    FROM 
        movie_info mi
    JOIN 
        movie_details m ON mi.movie_id = m.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    hd.rating,
    ad.name AS top_actor,
    ad.acted_movies
FROM 
    movie_details md
LEFT JOIN 
    highest_rated hd ON md.movie_id = hd.movie_id
LEFT JOIN 
    (SELECT 
         person_id, name, acted_movies 
     FROM 
         actor_details 
     WHERE 
         actor_rank = 1) ad ON ad.person_id IN (
                 SELECT 
                     c.person_id 
                 FROM 
                     cast_info c 
                 WHERE 
                     c.movie_id = md.movie_id
            )
WHERE 
    (md.total_actors > 5 AND md.production_year > 2000)
    OR
    (hd.rating != 'No Ratings' AND ad.acted_movies > 10)
ORDER BY 
    md.production_year DESC, md.title ASC;
