WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS production_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 3
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
)
SELECT 
    rm.title,
    rm.production_year,
    ta.name AS top_actor,
    mk.keywords,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.title_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')) AS box_office_count
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_info mi ON rm.title_id = mi.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
INNER JOIN 
    TopActors ta ON EXISTS (
        SELECT 1
        FROM cast_info ci
        WHERE ci.movie_id = rm.title_id AND ci.person_id = ta.actor_id
    )
WHERE 
    (mi.info IS NULL OR mi.info NOT LIKE '%low budget%')
AND 
    rm.production_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    mk.keywords;
