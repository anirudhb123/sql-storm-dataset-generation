
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
RecentActors AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COUNT(DISTINCT r.movie_id) AS movie_count
    FROM 
        aka_name p
    JOIN 
        cast_info r ON p.person_id = r.person_id
    WHERE 
        r.id IN (
            SELECT 
                id 
            FROM 
                complete_cast 
            WHERE 
                status_id = 1
        )
    GROUP BY 
        p.id, p.name
),
MoviesWithInfo AS (
    SELECT 
        m.title,
        m.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ra.name AS recent_actor,
    ra.movie_count,
    mw.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    RecentActors ra ON rm.actor_count = ra.movie_count
LEFT JOIN 
    MoviesWithInfo mw ON rm.title = mw.title
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC
LIMIT 50;
