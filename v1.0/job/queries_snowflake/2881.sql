
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actors,
        COALESCE(SUM(CASE WHEN mc.note LIKE '%production%' THEN 1 ELSE 0 END), 0) AS production_companies
    FROM 
        TopRankedMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON cc.subject_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.production_companies,
    CASE 
        WHEN md.production_companies > 2 THEN 'High Production'
        WHEN md.production_companies BETWEEN 1 AND 2 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_rating
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
