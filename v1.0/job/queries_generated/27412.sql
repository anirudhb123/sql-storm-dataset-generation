WITH movie_keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mkc.keyword_count,
        ROW_NUMBER() OVER (ORDER BY mkc.keyword_count DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword_count mkc ON m.id = mkc.movie_id
    WHERE 
        m.production_year >= 2000
),
actor_movie_count AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
highest_actor_movies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.keyword_count,
        ac.actor_count
    FROM 
        ranked_movies r
    JOIN 
        actor_movie_count ac ON r.movie_id = ac.movie_id
    WHERE 
        r.rank <= 10
),
final_results AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        h.keyword_count,
        h.actor_count,
        (h.keyword_count * h.actor_count) AS score
    FROM 
        highest_actor_movies h
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keyword_count,
    f.actor_count,
    f.score
FROM 
    final_results f
ORDER BY 
    f.score DESC;
