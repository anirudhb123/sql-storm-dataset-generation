WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(t.production_year) AS last_movie_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id
),
AboveAverageActors AS (
    SELECT 
        amc.person_id,
        amc.movie_count
    FROM 
        ActorMovieCounts amc
    WHERE 
        amc.movie_count > (SELECT AVG(movie_count) FROM ActorMovieCounts)
),
PerformingActors AS (
    SELECT 
        a.person_id,
        a.name,
        ROW_NUMBER() OVER (ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        AboveAverageActors aa ON a.person_id = aa.person_id
)
SELECT 
    pa.actor_rank,
    pa.name AS actor_name,
    rm.movie_title,
    rm.production_year,
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year >= 2000 AND rm.production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category,
    COALESCE(special_note.note, 'N/A') AS special_note
FROM 
    PerformingActors pa
LEFT JOIN 
    RankedMovies rm ON pa.actor_rank = rm.rank_per_year
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    title t ON rm.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Special Note')
LEFT JOIN 
    (SELECT movie_id, info AS note FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Special Note')) special_note 
    ON rm.movie_id = special_note.movie_id
WHERE 
    rm.movie_title IS NOT NULL
ORDER BY 
    pa.actor_rank, rm.production_year DESC
OFFSET 10 LIMIT 10;
