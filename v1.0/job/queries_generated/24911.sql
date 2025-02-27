WITH RecursiveMovieActors AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
),
ActorMovieCount AS (
    SELECT 
        movie_id,
        COUNT(actor_name) AS actor_count
    FROM 
        RecursiveMovieActors
    GROUP BY 
        movie_id
),
YearWiseTitle AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        a.actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        ActorMovieCount a ON t.id = a.movie_id
    WHERE 
        t.production_year IS NOT NULL 
        AND (t.production_year % 4 = 0 OR a.actor_count IS NULL)
    GROUP BY 
        t.title, t.production_year, a.actor_count
),
PopularTitles AS (
    SELECT 
        title,
        production_year,
        actor_count,
        DENSE_RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rnk
    FROM 
        YearWiseTitle
    WHERE 
        actor_count > 0
)
SELECT
    yt.title,
    yt.production_year,
    yt.actor_count,
    yt.keyword_count,
    CASE 
        WHEN yt.actor_count IS NULL THEN 'N/A'
        WHEN yt.actor_count >= 5 THEN 'Highly Casted' 
        WHEN yt.actor_count BETWEEN 1 AND 4 THEN 'Moderate Cast'
        ELSE 'Not Casted'
    END AS cast_status,
    COALESCE(yt.actor_count, 0) as safe_actor_count
FROM 
    PopularTitles yt
WHERE 
    yt.rnk <= 5
ORDER BY 
    yt.production_year DESC, yt.keyword_count DESC;

-- Incorporating a NULL check to avoid issues of division by zero in a potential scale factor calculation
WITH MovieInfoSummary AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No Info') AS info,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        COUNT(DISTINCT ca.person_id) AS total_actors
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    GROUP BY 
        m.id, mi.info
)
SELECT 
    movie_id,
    info,
    total_keywords,
    total_actors,
    CASE 
        WHEN total_keywords = 0 THEN 'No Keywords Available'
        ELSE CAST(total_actors AS FLOAT) / NULLIF(total_keywords, 0) END AS actor_to_keyword_ratio
FROM 
    MovieInfoSummary
WHERE 
    total_actors > 0
ORDER BY 
    actor_to_keyword_ratio DESC;
