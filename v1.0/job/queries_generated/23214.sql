WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(DISTINCT m.company_id) OVER (PARTITION BY t.id) AS company_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_companies AS m ON t.id = m.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        ak.name AS actor_name, 
        t.title AS movie_title,
        COUNT(c.id) AS actor_count,
        ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM 
        aka_name AS ak
    INNER JOIN 
        cast_info AS c ON ak.person_id = c.person_id
    INNER JOIN 
        aka_title AS t ON c.movie_id = t.id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        ak.name, t.title
),
MovieDetails AS (
    SELECT 
        rm.title AS movie_title,
        rm.production_year,
        COALESCE(SUM(aci.actor_count), 0) AS total_actors,
        COALESCE(STRING_AGG(DISTINCT ac.actor_name, ', '), '') AS all_actors,
        rm.company_count,
        CASE 
            WHEN rm.company_count > 0 THEN 'Produced'
            ELSE 'Not Produced'
        END AS production_status
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        ActorsInMovies AS aci ON rm.title = aci.movie_title
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = rm.id
    GROUP BY 
        rm.title, rm.production_year, rm.company_count
)
SELECT 
    md.movie_title,
    md.production_year,
    md.total_actors,
    md.all_actors,
    md.company_count,
    md.production_status,
    CASE 
        WHEN md.production_year <= 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2001 AND 2010 THEN 'Modern Era'
        ELSE 'Contemporary'
    END AS era,
    CASE 
        WHEN md.all_actors IS NULL OR md.all_actors = '' THEN 'No actors found'
        ELSE md.all_actors
    END AS actors_info
FROM 
    MovieDetails AS md
WHERE 
    md.total_actors > 5 OR md.production_status = 'Produced'
ORDER BY 
    md.production_year DESC, md.company_count ASC
LIMIT 10;
