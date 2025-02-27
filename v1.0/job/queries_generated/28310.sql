WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(pi.info) AS avg_rating
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
    GROUP BY 
        m.id, m.title, m.production_year
), 
highest_rated AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        avg_rating,
        RANK() OVER (ORDER BY avg_rating DESC) AS rating_rank
    FROM 
        ranked_movies
),
movie_details AS (
    SELECT
        h.movie_id,
        h.title,
        h.production_year,
        h.actor_count,
        h.avg_rating,
        k.keyword,
        c.kind AS company_type
    FROM 
        highest_rated h
    LEFT JOIN 
        movie_keyword mk ON h.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON h.movie_id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.avg_rating,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_type, ', ') AS companies
FROM 
    movie_details md
WHERE 
    md.rating_rank <= 10
GROUP BY 
    md.movie_id, md.title, md.production_year, md.actor_count, md.avg_rating
ORDER BY 
    md.avg_rating DESC;
