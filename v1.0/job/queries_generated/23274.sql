WITH Recursive_Cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        1 AS depth,
        c.name AS actor_name
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        c.name IS NOT NULL
    UNION ALL
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        rc.depth + 1,
        c.name AS actor_name
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        Recursive_Cast rc ON ci.movie_id = rc.movie_id AND rc.depth < 5
    WHERE 
        c.name IS NOT NULL
),
Movie_Details AS (
    SELECT 
        t.title,
        t.production_year,
        ka.keyword AS genre,
        COUNT(DISTINCT rc.actor_name) AS actor_count,
        AVG(CASE WHEN t.production_year IS NOT NULL THEN t.production_year ELSE 0 END) AS avg_production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT rc.actor_name) DESC) AS production_year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ka ON mk.keyword_id = ka.id
    LEFT JOIN 
        Recursive_Cast rc ON t.id = rc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, ka.keyword
),
Filtered_Movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.genre,
        md.actor_count
    FROM 
        Movie_Details md
    WHERE 
        md.actor_count > 1
        AND (md.production_year >= 2000 OR md.genre IS NULL)
),
Aggregate_Stats AS (
    SELECT 
        genre,
        COUNT(*) AS total_movies,
        AVG(actor_count) AS avg_actor_count,
        MIN(actor_count) AS min_actor_count,
        MAX(actor_count) AS max_actor_count,
        SUM(CASE WHEN actor_count = 1 THEN 1 ELSE 0 END) AS solo_performances
    FROM 
        Filtered_Movies
    GROUP BY 
        genre
)
SELECT 
    agg.genre,
    agg.total_movies,
    agg.avg_actor_count,
    agg.min_actor_count,
    agg.max_actor_count,
    agg.solo_performances,
    CASE 
        WHEN agg.total_movies = 0 THEN 'No movies found' 
        ELSE 'Movies found' 
    END AS status
FROM 
    Aggregate_Stats agg
ORDER BY 
    agg.total_movies DESC NULLS LAST;
