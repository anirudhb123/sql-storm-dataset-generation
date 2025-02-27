WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
HighPerformingActors AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) > 3
),
MovieKeywords AS (
    SELECT 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS person_name,
        pi.info AS bio_info,
        COALESCE(pi.note, 'No additional notes available') AS info_note
    FROM 
        name p
    LEFT JOIN 
        person_info pi ON p.id = pi.person_id
)
SELECT 
    h.actor_name,
    h.movie_count,
    m.title AS movie_title,
    m.production_year,
    k.keywords,
    a.person_name,
    a.bio_info,
    a.info_note
FROM 
    HighPerformingActors h
JOIN 
    RankedMovies r ON h.actor_name = r.actor_name
JOIN 
    MovieKeywords m ON r.movie_title = m.title
JOIN 
    ActorDetails a ON r.actor_name = a.person_name
WHERE 
    r.rn <= 5
ORDER BY 
    h.movie_count DESC, 
    r.production_year ASC;
