WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year > 2000
),
DirectorMovies AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role = 'Director'
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        d.director_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        RankedMovies t
    LEFT JOIN 
        DirectorMovies d ON t.id = d.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year, d.director_count
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.director_count, 0) AS director_count,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count IS NULL THEN 'No Keywords'
        WHEN md.keyword_count = 0 THEN 'No Keywords Available'
        ELSE 'Keywords Present'
    END AS keyword_status
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 2 
    OR (md.keyword_count IS NULL AND md.director_count IS NOT NULL)
ORDER BY 
    md.production_year DESC, 
    md.title;
