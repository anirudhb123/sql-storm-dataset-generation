WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(t.production_year) AS last_movie_year
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        RankedMovies t ON t.title_id = c.movie_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        ac.movie_count,
        ac.last_movie_year
    FROM 
        aka_name a
    INNER JOIN 
        ActorMovieCounts ac ON a.person_id = ac.person_id
    WHERE 
        ac.movie_count > 5 AND ac.last_movie_year >= 2020
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cmp.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        t.title,
        t.production_year,
        cm.company_count
    FROM 
        aka_title t
    LEFT JOIN 
        CompanyMovies cm ON t.id = cm.movie_id
    WHERE 
        cm.company_count IS NULL OR cm.company_count >= 3
    ORDER BY 
        t.production_year DESC
),
MovieActors AS (
    SELECT 
        t.id AS title_id,
        a.id AS actor_id,
        a.name
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.gender IS NOT NULL AND a.name IS NOT NULL
),
FinalOutput AS (
    SELECT 
        ma.title_id,
        ma.name AS actor_name,
        COUNT(DISTINCT ma.actor_id) OVER (PARTITION BY ma.title_id) AS total_actors,
        CASE 
            WHEN COUNT(DISTINCT ma.actor_id) OVER (PARTITION BY ma.title_id) > 5 THEN 'Blockbuster'
            ELSE 'Indie'
        END AS classification
    FROM 
        MovieActors ma
)
SELECT 
    fo.title_id,
    fo.actor_name,
    fo.total_actors,
    fo.classification
FROM 
    FinalOutput fo
WHERE 
    fo.classification = 'Blockbuster'
ORDER BY 
    fo.total_actors DESC, fo.actor_name;
