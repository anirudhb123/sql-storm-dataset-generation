WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(CAST(m.production_year AS text), 'Unknown') AS production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT COALESCE(cn.name, 'No Company')) AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        m.production_year IS NULL OR m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
actor_details AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movies,
        RANK() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON ci.person_id = a.person_id
    JOIN 
        aka_title m ON m.id = ci.movie_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
),
rating_details AS (
    SELECT 
        title.movie_id,
        AVG(CASE WHEN ri.info_type_id = 1 THEN CAST(ri.info AS FLOAT) END) AS average_rating
    FROM 
        movie_info ri
    JOIN 
        title ON title.id = ri.movie_id
    WHERE 
        ri.info_type_id = 1
    GROUP BY 
        title.movie_id
),
combined AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        COALESCE(rd.average_rating, 0) AS average_rating,
        ad.actor_count
    FROM 
        movie_details md
    LEFT JOIN 
        (SELECT 
            ci.movie_id, 
            COUNT(DISTINCT ci.person_id) AS actor_count 
         FROM 
            cast_info ci
         GROUP BY 
            ci.movie_id) ad ON ad.movie_id = md.movie_id
    LEFT JOIN 
        rating_details rd ON rd.movie_id = md.movie_id
)
SELECT 
    c.movie_id,
    c.title,
    c.production_year,
    c.keywords,
    c.companies,
    c.average_rating,
    COALESCE(ad.movies, 'No actors listed') AS actor_movies
FROM 
    combined c
LEFT JOIN 
    actor_details ad ON ad.movie_id = c.movie_id
WHERE 
    (c.average_rating IS NULL OR c.average_rating > 7) 
    AND (c.production_year IS NOT NULL AND c.production_year <> 'Unknown')
ORDER BY 
    c.average_rating DESC,
    c.title ASC;
