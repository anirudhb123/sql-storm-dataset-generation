WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        c.role_id,
        r.role,
        COALESCE(NULLIF(m.year, 0), 'Unknown') AS release_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        (SELECT movie_id, MIN(production_year) AS year FROM movie_info GROUP BY movie_id) m ON c.movie_id = m.movie_id
    WHERE 
        a.name IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    ad.name AS actor_name,
    ad.role,
    cs.company_count,
    cs.company_names,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY COUNT(ad.person_id) DESC) AS actor_rank
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.title_rank <= 5
    AND (ad.release_year IS NULL OR ad.release_year > 2000)
ORDER BY 
    rm.production_year DESC, actor_rank;
