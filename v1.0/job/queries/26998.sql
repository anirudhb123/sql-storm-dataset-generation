WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(ci.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        k.keyword IN ('action', 'drama', 'comedy')
    GROUP BY 
        t.id, k.keyword, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 5
)
SELECT 
    t.title,
    t.production_year,
    k.keyword,
    a.name AS main_actor,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    COALESCE(SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END), 0) AS lead_actor_count
FROM 
    TopRankedMovies t
JOIN 
    cast_info ci ON t.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    keyword k ON k.keyword = t.keyword
GROUP BY 
    t.movie_id, t.title, t.production_year, k.keyword, a.name
ORDER BY 
    t.production_year DESC, total_actors DESC, t.title;
