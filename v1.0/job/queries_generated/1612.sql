WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        title_id, title, production_year, total_cast
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
PersonInfo AS (
    SELECT 
        a.name AS actor_name,
        pi.info AS actor_bio
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
)
SELECT 
    tr.title,
    tr.production_year,
    tr.total_cast,
    STRING_AGG(DISTINCT pi.actor_name, ', ') AS actors,
    COALESCE(MAX(pi.actor_bio), 'No biography available') AS sample_bio
FROM 
    TopRankedMovies tr
LEFT JOIN 
    cast_info c ON tr.title_id = c.movie_id
LEFT JOIN 
    PersonInfo pi ON c.person_id = pi.actor_name
GROUP BY 
    tr.title_id, tr.title, tr.production_year, tr.total_cast
ORDER BY 
    tr.production_year DESC, tr.total_cast DESC;
