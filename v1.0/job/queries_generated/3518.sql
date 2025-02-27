WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        r.movie_id,
        r.movie_title,
        r.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorCounts ac ON r.movie_id = ac.movie_id
    LEFT JOIN 
        MovieKeywords mk ON r.movie_id = mk.movie_id
)
SELECT 
    d.movie_title,
    d.production_year,
    d.actor_count,
    CASE 
        WHEN d.actor_count > 10 THEN 'Popular'
        WHEN d.actor_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS popularity,
    d.keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = d.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info_count
FROM 
    DetailedMovieInfo d
WHERE 
    d.year_rank <= 5
ORDER BY 
    d.production_year DESC, d.actor_count DESC;
