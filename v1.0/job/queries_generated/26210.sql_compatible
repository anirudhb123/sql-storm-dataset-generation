
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        b.name AS director_name,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title AS a
    JOIN 
        movie_companies AS mc ON a.id = mc.movie_id
    JOIN 
        company_name AS b ON mc.company_id = b.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'director')
    JOIN 
        cast_info AS c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, b.name
),
popular_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
combined_results AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.director_name,
        rm.actor_count,
        COALESCE(p.keyword, 'No Keywords') AS popular_keyword,
        COALESCE(p.keyword_count, 0) AS keyword_freq
    FROM 
        ranked_movies AS rm
    LEFT JOIN 
        popular_keywords AS p ON rm.title = (SELECT title FROM aka_title WHERE id = p.movie_id LIMIT 1)
    WHERE 
        rm.year_rank <= 5 AND rm.production_year BETWEEN 2000 AND 2023
)

SELECT 
    c.production_year,
    COUNT(c.title) AS total_movies,
    AVG(c.actor_count) AS avg_actors,
    ARRAY_AGG(DISTINCT c.popular_keyword) AS sampled_keywords
FROM 
    combined_results AS c
GROUP BY 
    c.production_year
ORDER BY 
    c.production_year DESC;
