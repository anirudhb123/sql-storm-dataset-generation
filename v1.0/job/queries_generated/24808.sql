WITH gender_stats AS (
    SELECT 
        n.gender,
        COUNT(DISTINCT ca.id) AS actor_count,
        COUNT(DISTINCT ti.id) AS title_count,
        AVG(EXTRACT(YEAR FROM CURRENT_DATE) - ti.production_year) AS avg_age_of_movies
    FROM 
        aka_name AS n
    JOIN 
        cast_info AS ca ON n.person_id = ca.person_id
    JOIN 
        aka_title AS ti ON ca.movie_id = ti.movie_id
    GROUP BY 
        n.gender
),
popular_keywords AS (
    SELECT 
        mw.keyword,
        COUNT(DISTINCT mi.movie_id) AS keyword_count
    FROM 
        movie_keyword AS mw
    JOIN 
        movie_info AS mi ON mw.movie_id = mi.movie_id
    GROUP BY 
        mw.keyword
    HAVING 
        COUNT(DISTINCT mi.movie_id) > 5
),
movie_tally AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT m.movie_id) AS total_movies,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_actors
    FROM 
        title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN 
        movie_info AS mi ON t.id = mi.movie_id
    GROUP BY 
        t.production_year
)
SELECT 
    gs.gender,
    gs.actor_count,
    gs.title_count,
    gs.avg_age_of_movies,
    mk.keyword,
    mk.keyword_count,
    mt.production_year,
    mt.total_movies,
    mt.total_actors
FROM 
    gender_stats AS gs
JOIN 
    popular_keywords AS mk ON gs.actor_count > 10
LEFT JOIN 
    movie_tally AS mt ON mt.total_actors > 10 AND mt.production_year >= 2000
WHERE 
    gs.gender IS NOT NULL
ORDER BY 
    gs.actor_count DESC, 
    mk.keyword_count DESC, 
    mt.total_movies ASC;
