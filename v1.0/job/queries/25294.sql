
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),

InfluentialMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT mc.note, ', ') AS company_notes
    FROM 
        RankedMovies rm
    JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    GROUP BY 
        rm.movie_id, rm.title
),

FinalResults AS (
    SELECT 
        im.movie_id,
        im.title,
        im.company_count,
        im.company_notes,
        rm.cast_count,
        rm.actor_names
    FROM 
        InfluentialMovies im
    JOIN 
        RankedMovies rm ON im.movie_id = rm.movie_id
    WHERE 
        rm.cast_count > 10
    ORDER BY 
        im.company_count DESC, rm.cast_count DESC
)

SELECT 
    fr.title,
    at.production_year,
    fr.company_count,
    fr.actor_names,
    fr.company_notes
FROM 
    FinalResults fr
JOIN 
    aka_title at ON fr.movie_id = at.id
WHERE 
    at.production_year >= 2000
LIMIT 100;
