WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_details AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
),
high_impact_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        AVG(kd.keyword_ranking) AS avg_keyword_rank
    FROM 
        (
            SELECT 
                mk.movie_id,
                md.keyword AS keyword,
                CASE 
                    WHEN md.keyword IN ('Action', 'Drama', 'Thriller') THEN 1
                    ELSE 0
                END AS keyword_ranking
            FROM 
                movie_keyword mk
            JOIN 
                keyword md ON mk.keyword_id = md.id
        ) kd
    JOIN 
        ranked_movies m ON kd.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, m.title
    HAVING 
        AVG(kd.keyword_ranking) > 0
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    hm.avg_keyword_rank
FROM 
    ranked_movies r
LEFT JOIN 
    actor_details ad ON r.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name IS NOT NULL))
LEFT JOIN 
    high_impact_movies hm ON r.movie_id = hm.movie_id
WHERE 
    r.rank <= 10 AND
    (hm.avg_keyword_rank IS NOT NULL OR ad.movie_count >= 5)
ORDER BY 
    r.production_year DESC, ad.movie_count DESC;
