
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        t.production_year
    FROM 
        title t
    LEFT JOIN 
        MovieKeywordCounts mkc ON t.id = mkc.movie_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        ci.movie_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(ad.actor_name) AS total_actors,
    MAX(ad.actor_order) AS max_actor_order,
    STRING_AGG(ad.actor_name, ', ') AS actor_names,
    CASE 
        WHEN MAX(ad.actor_order) > 5 THEN 'Larger Cast'
        ELSE 'Smaller Cast'
    END AS cast_size
FROM 
    TopMovies tm
LEFT JOIN 
    ActorDetails ad ON tm.movie_id = ad.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
HAVING 
    COUNT(ad.actor_name) > 0
ORDER BY 
    tm.production_year DESC,
    total_actors DESC
LIMIT 100;
