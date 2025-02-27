WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.movie_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(COALESCE(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END, 0)) AS lead_actor_ratio
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        aq.actor_name,
        aq.movie_count,
        aq.lead_actor_ratio
    FROM 
        RankedMovies rm
    LEFT JOIN 
        (SELECT 
             m.movie_id, 
             a.name AS actor_name 
         FROM 
             cast_info m 
         JOIN 
             aka_name a ON m.person_id = a.person_id
         WHERE 
             m.nr_order = 1) aq ON rm.movie_id = aq.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.actor_name, 'Unknown Actor') AS actor_name,
    md.movie_count,
    md.lead_actor_ratio,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM 
    MovieDetails md
WHERE 
    md.rank <= 5
ORDER BY 
    md.production_year DESC, md.movie_count DESC;
