WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.person_id,
        t.id AS movie_id,
        COALESCE(GROUP_CONCAT(DISTINCT a.name), 'Unknown') AS actor_names,
        COUNT(DISTINCT t.id) AS movies_count
    FROM 
        cast_info c
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id, t.id
),
AggregateGenres AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS genre_count,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS associated_keywords
    FROM 
        cast_info c
    JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        c.person_id
),
OuterQuery AS (
    SELECT 
        p.id AS person_id,
        p.gender,
        COALESCE(am.actor_names, 'No Roles') AS actor_names,
        ag.genre_count,
        ag.associated_keywords,
        CASE 
            WHEN am.movies_count > 5 THEN 'Frequent Actor' 
            ELSE 'Occasional Actor' 
        END AS actor_type
    FROM 
        name p
    LEFT JOIN 
        ActorMovies am ON p.id = am.person_id
    LEFT JOIN 
        AggregateGenres ag ON p.id = ag.person_id
    WHERE 
        p.gender IS NOT NULL
)

SELECT 
    oq.person_id,
    oq.gender,
    oq.actor_names,
    oq.genre_count,
    oq.associated_keywords,
    oq.actor_type,
    rm.title,
    rm.year_rank
FROM 
    OuterQuery oq
LEFT JOIN 
    RankedMovies rm ON oq.genre_count > 3 AND oq.person_id IN (
        SELECT 
            c.person_id
        FROM 
            cast_info c
        JOIN 
            title t ON c.movie_id = t.id
        WHERE 
            t.production_year = (SELECT MAX(t2.production_year) FROM title t2)
    )
WHERE 
    oq.actor_type = 'Frequent Actor'
ORDER BY 
    oq.person_id, rm.year_rank DESC
LIMIT 100;
