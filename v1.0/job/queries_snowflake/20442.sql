
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank,
        COALESCE(SUBSTR(t.title, -4), 'Unknown Year') AS year_extracted
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
HighCastMovies AS (
    SELECT 
        m.movie_id,
        COUNT(*) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors
    FROM 
        cast_info m
    JOIN 
        aka_name ak ON m.person_id = ak.person_id
    GROUP BY 
        m.movie_id
    HAVING 
        COUNT(*) > 10
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        hcm.cast_count,
        hcm.actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        HighCastMovies hcm ON rm.movie_id = hcm.movie_id
),
NullLogicMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        CASE 
            WHEN md.cast_count IS NULL THEN 'No Cast Info'
            ELSE md.actors
        END AS actors_info
    FROM 
        MovieDetails md
    WHERE 
        md.cast_count IS NOT NULL OR md.title ILIKE '%(Unreleased)%'
)

SELECT 
    nm.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    m.actors_info,
    COUNT(DISTINCT mi.info) AS info_count,
    SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present
FROM 
    NullLogicMovies m
JOIN 
    cast_info c ON c.movie_id = m.movie_id
JOIN 
    aka_name nm ON c.person_id = nm.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    nm.name, m.title, m.production_year, m.actors_info
HAVING 
    COUNT(DISTINCT mi.info) > 0
ORDER BY 
    m.production_year DESC, COUNT(DISTINCT mi.info) DESC
LIMIT 50;
