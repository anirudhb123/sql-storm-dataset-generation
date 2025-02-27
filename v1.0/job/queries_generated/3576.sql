WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
MovieDetails AS (
    SELECT
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COALESCE(SUM(mb.id), 0) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mb ON tm.production_year = (SELECT production_year FROM aka_title WHERE id = mb.movie_id)
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.company_count,
    md.keyword_count,
    CASE 
        WHEN md.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Exist' 
    END AS company_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
