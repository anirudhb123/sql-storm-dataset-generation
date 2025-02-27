WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank,
        COUNT(DISTINCT m.company_id) AS company_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_series'))
    GROUP BY 
        a.id, a.name, t.title, t.production_year
),
MoviesWithActorCount AS (
    SELECT 
        t.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(t.production_year) AS latest_year
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title
),
AlternativeMovies AS (
    SELECT 
        t.title,
        AVG(m.info_length) AS average_info_length
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id,
            CHAR_LENGTH(info) AS info_length
        FROM 
            movie_info
        WHERE 
            note IS NULL OR note <> 'duplicate'
    ) m ON t.id = m.movie_id
    GROUP BY 
        t.title
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    rt.rank,
    COALESCE(m.actor_count, 0) AS total_actors,
    COALESCE(am.average_info_length, 0) AS avg_info_length,
    rt.company_count
FROM 
    RankedTitles rt
LEFT JOIN 
    MoviesWithActorCount m ON rt.movie_title = m.title
LEFT JOIN 
    AlternativeMovies am ON rt.movie_title = am.title
WHERE 
    rt.rank <= 3
ORDER BY 
    rt.actor_name, rt.production_year DESC, rt.movie_title;
