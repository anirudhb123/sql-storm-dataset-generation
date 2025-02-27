WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name an ON c.person_id = an.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.total_cast,
        CASE
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era,
        (SELECT STRING_AGG(k.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = m.movie_id) AS keywords
    FROM 
        ranked_movies m
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.era,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.total_cast > 5 
    AND md.era = 'Modern'
ORDER BY 
    md.total_cast DESC, md.production_year ASC;
