
WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT cc.subject_id) AS complete_cast_count,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id = (
            SELECT id FROM kind_type WHERE kind = 'movie' LIMIT 1
        )
    GROUP BY 
        t.title, t.production_year, a.name
),
ranked_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name,
        keywords,
        complete_cast_count,
        production_companies,
        RANK() OVER (ORDER BY complete_cast_count DESC, production_companies DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    movie_title, 
    production_year, 
    actor_name,
    keywords,
    complete_cast_count,
    production_companies,
    rank
FROM 
    ranked_movies 
WHERE 
    rank <= 10
ORDER BY 
    rank;
