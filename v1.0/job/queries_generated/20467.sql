WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords,
        t.kind AS movie_type,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            WHEN m.production_year < 1980 THEN 'Classic'
            WHEN m.production_year BETWEEN 1980 AND 1999 THEN 'Modern'
            ELSE 'Recent'
        END AS era,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT p.info) FILTER (WHERE p.info_type_id = 1) AS awards
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        title t ON m.id = t.id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    GROUP BY 
        m.id, m.title, m.production_year, t.kind
),
RankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        keywords,
        movie_type,
        era,
        actor_count,
        awards,
        ROW_NUMBER() OVER (PARTITION BY era ORDER BY actor_count DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keywords,
    rm.movie_type,
    rm.era,
    rm.actor_count,
    rm.awards,
    CASE
        WHEN rm.actor_count IS NULL THEN 'No Actors'
        WHEN rm.actor_count < 5 THEN 'Few Actors'
        ELSE 'Many Actors'
    END AS actor_count_desc
FROM 
    RankedMovies rm
WHERE 
    rm.rn <= 5
    AND (rm.production_year IS NOT NULL OR rm.actor_count IS NOT NULL)
ORDER BY 
    rm.era, rm.actor_count DESC;
