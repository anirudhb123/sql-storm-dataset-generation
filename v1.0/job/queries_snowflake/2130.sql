
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info AS c
    GROUP BY 
        c.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        COALESCE(m.info, 'No Info') AS movie_info
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_info AS m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, m.info
)
SELECT 
    md.movie_id,
    md.title,
    md.actors,
    md.movie_info,
    COALESCE(amc.movie_count, 0) AS total_actors,
    rm.rn AS rank_by_year
FROM 
    MovieDetails AS md
LEFT JOIN 
    ActorMovieCounts AS amc ON md.movie_id = amc.person_id
JOIN 
    RankedMovies AS rm ON md.movie_id = rm.movie_id
WHERE 
    md.movie_info IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    md.title ASC;
