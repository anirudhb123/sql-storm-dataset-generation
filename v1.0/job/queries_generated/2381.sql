WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.imdb_index) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
AggregatedCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
DetailedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ac.total_cast,
        ac.note_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        AggregatedCast ac ON t.id = ac.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
)
SELECT 
    dt.title,
    dt.production_year,
    COALESCE(k.keyword, 'No Keyword') AS keyword,
    dt.total_cast,
    dt.note_count
FROM 
    DetailedMovies dt
LEFT JOIN 
    RankedTitles rt ON dt.production_year = rt.production_year AND dt.title = rt.title
WHERE 
    dt.total_cast > 5
ORDER BY 
    dt.production_year DESC, 
    dt.title ASC
LIMIT 50;
