WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
), ActingRoles AS (
    SELECT 
        p.id AS person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    GROUP BY 
        p.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.name, 'Unknown Actor') AS lead_actor,
        rm.cast_count,
        rm.year_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActingRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.year_rank <= 3
)
SELECT 
    md.title,
    md.production_year,
    md.lead_actor,
    md.cast_count,
    (SELECT AVG(m.production_year) 
     FROM RankedMovies m 
     WHERE m.cast_count > 0 AND m.production_year BETWEEN md.production_year - 5 AND md.production_year + 5) AS avg_year
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
