WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STATS_AGG(mn.name) AS company_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name mn ON mc.company_id = mn.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE year_rank <= 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.actors,
    fm.company_names,
    fm.keywords
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;
