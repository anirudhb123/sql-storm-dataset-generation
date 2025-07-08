
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(c.rank, 0) AS movie_rank,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        (SELECT movie_id, 
                DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
         FROM complete_cast
         GROUP BY movie_id) c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, c.rank
),
HighRatedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.movie_rank,
        md.keyword_count,
        md.actors
    FROM 
        MovieDetails md
    WHERE 
        md.production_year > 2000 
        AND md.movie_rank <= 10
),
RecentMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 5
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    h.title AS high_rated_title,
    h.production_year AS high_rated_year,
    h.actors AS featured_actors,
    r.title AS recent_title,
    r.actor_count AS recent_actor_count
FROM 
    HighRatedMovies h
FULL OUTER JOIN 
    RecentMovies r ON h.production_year = r.production_year
WHERE 
    (h.movie_rank IS NOT NULL OR r.actor_count IS NOT NULL)
ORDER BY 
    h.production_year DESC NULLS LAST, 
    r.actor_count DESC NULLS FIRST;
