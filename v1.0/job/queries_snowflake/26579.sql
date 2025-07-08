WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        k.keyword AS genre
    FROM 
        aka_title t
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        cast_info ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
actor_distribution AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_genre_stats AS (
    SELECT 
        md.movie_id,
        COUNT(DISTINCT md.genre) AS genre_count,
        md.title,
        md.production_year,
        actor_count
    FROM 
        movie_details md
    JOIN 
        actor_distribution ad ON md.movie_id = ad.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, actor_count
),
final_output AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        genre_count,
        CASE 
            WHEN genre_count = 0 THEN 'No Genres Found'
            ELSE 'Escaped Genres'
        END AS genre_status
    FROM 
        movie_genre_stats
    WHERE 
        actor_count > 5
)

SELECT 
    *,
    RANK() OVER (ORDER BY production_year DESC, actor_count DESC) AS rank
FROM 
    final_output
ORDER BY 
    production_year DESC, 
    rank;
