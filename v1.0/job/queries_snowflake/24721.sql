
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.title IS NOT NULL
        AND t.production_year BETWEEN 1990 AND YEAR(DATE '2024-10-01')
),
FilteredCast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COALESCE(c.note, 'No note provided') AS note,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
        AND c.nr_order IS NOT NULL
),
SelectedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        LENGTH(m.title) AS title_length,
        COALESCE(AVG(fc.actor_rank), 0) AS avg_actor_rank
    FROM 
        RankedMovies m
    LEFT JOIN 
        FilteredCast fc ON m.movie_id = fc.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    s.title,
    s.production_year,
    s.title_length,
    CASE 
        WHEN s.avg_actor_rank IS NULL THEN 'No actors yet'
        WHEN s.avg_actor_rank = 1 THEN 'Starring'
        ELSE 'Supporting'
    END AS actor_classification,
    s.avg_actor_rank,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = s.movie_id AND mi.note IS NOT NULL) AS non_null_notes_count,
    (SELECT LISTAGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = s.movie_id) AS keywords,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_link ml WHERE ml.movie_id = s.movie_id) THEN 'Has Links'
        ELSE 'No Links'
    END AS link_status
FROM 
    SelectedMovies s
WHERE 
    (s.title_length > 10 OR s.avg_actor_rank > 2)
    AND (s.production_year IS NOT NULL OR s.title IS DISTINCT FROM 'Undefined Title')
ORDER BY 
    s.production_year DESC, s.title_length ASC
LIMIT 100;
