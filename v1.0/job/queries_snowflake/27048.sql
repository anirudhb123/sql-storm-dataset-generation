
WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 3
),
AggregatedData AS (
    SELECT 
        a.person_id,
        COUNT(tm.aka_id) AS movie_count,
        LISTAGG(tm.movie_title, '; ') WITHIN GROUP (ORDER BY tm.movie_title) AS top_movie_titles
    FROM 
        aka_name a
    JOIN 
        TopMovies tm ON a.id = tm.aka_id
    GROUP BY 
        a.person_id
)
SELECT 
    p.id AS person_id,
    p.name,
    ad.movie_count,
    ad.top_movie_titles
FROM 
    aka_name a
JOIN 
    AggregatedData ad ON a.person_id = ad.person_id
JOIN 
    name p ON a.person_id = p.imdb_id
WHERE 
    ad.movie_count > 0
ORDER BY 
    ad.movie_count DESC, 
    p.name;
