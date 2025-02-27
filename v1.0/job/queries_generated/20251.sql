WITH MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT CASE WHEN ak.name IS NOT NULL THEN ak.name END) AS actor_count,
        MAX(CASE WHEN ak.name IS NOT NULL THEN ak.name END) AS last_actor,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_actors
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        mc.actor_count,
        mc.all_actors
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        MovieCast mc ON t.id = mc.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year, mc.actor_count, mc.all_actors
),
RankedMovies AS (
    SELECT 
        title,
        production_year,
        keyword_count,
        actor_count,
        all_actors,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS keyword_rank,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS actor_rank
    FROM 
        MovieDetails
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        keyword_count,
        actor_count,
        all_actors
    FROM 
        RankedMovies
    WHERE 
        keyword_rank <= 5 OR actor_rank <= 5
)
SELECT 
    DISTINCT f.title,
    f.production_year,
    f.keyword_count,
    f.actor_count,
    f.all_actors,
    (CASE 
        WHEN f.actor_count IS NULL THEN 'No actors listed'
        WHEN f.actor_count > 10 THEN 'Blockbuster status'
        ELSE 'Independent film'
    END) AS film_status,
    COALESCE((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT id FROM aka_title WHERE title = f.title)), 0) AS additional_info_count
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.keyword_count DESC, 
    f.actor_count DESC;
