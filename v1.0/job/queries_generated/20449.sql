WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank_within_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
RecentMovies AS (
    SELECT 
        title,
        movie_id,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
ActorMovies AS (
    SELECT 
        a.name,
        rc.movie_id,
        rc.title,
        rc.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY rc.production_year DESC) AS recent_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RecentMovies rc ON ci.movie_id = rc.movie_id
),
FilteredActors AS (
    SELECT 
        name,
        movie_id,
        title,
        production_year
    FROM 
        ActorMovies
    WHERE 
        recent_rank < 4 -- Select actors who have appeared in less than 4 of the top movies
)
SELECT 
    f.name,
    f.title,
    f.production_year,
    COALESCE(k.keyword, 'No Keyword') AS keyword_info,
    CASE 
        WHEN f.movie_id IN (SELECT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'summary')) THEN 'Has Summary'
        ELSE 'No Summary Available'
    END AS summary_status
FROM 
    FilteredActors f
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    f.production_year IS NOT NULL -- Ensuring we only get movies with a production year
ORDER BY 
    f.production_year DESC, f.name;
