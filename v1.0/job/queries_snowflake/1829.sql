WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
high_actor_movies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
movie_details AS (
    SELECT 
        hm.title,
        hm.production_year,
        mh.info AS movie_info,
        c.name AS company_name
    FROM 
        high_actor_movies hm
    LEFT JOIN 
        movie_info mh ON hm.title = mh.info
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (
            SELECT 
                m.id
            FROM 
                aka_title m
            WHERE 
                m.title = hm.title AND m.production_year = hm.production_year
            LIMIT 1
        )
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.movie_info, 'No Information Available') AS movie_info,
    COALESCE(md.company_name, 'Independent') AS company_name
FROM 
    movie_details md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.title;
