WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_within_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        c.movie_id, ak.name, r.role
),
MoviesWithKeyWord AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ar.role_name, 'Unknown Role') AS role_name,
    COALESCE(mkw.keyword, 'No Keywords') AS keyword,
    ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.rank_within_year) AS year_movie_rank,
    SUM(CASE WHEN rm.production_year = EXTRACT(YEAR FROM CURRENT_DATE) THEN 1 ELSE 0 END) OVER () AS current_year_count,
    CASE 
        WHEN COUNT(DISTINCT ar.actor_name) > 3 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_density
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MoviesWithKeyWord mkw ON rm.movie_id = mkw.movie_id
WHERE 
    rm.rank_within_year < 5 -- Focus on top 4 ranked titles per year
GROUP BY 
    rm.movie_title, rm.production_year, ar.actor_name, ar.role_name, mkw.keyword
ORDER BY 
    rm.production_year DESC, rm.rank_within_year;
