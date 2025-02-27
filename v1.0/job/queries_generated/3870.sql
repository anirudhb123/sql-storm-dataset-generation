WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_actors
    FROM 
        RankedTitles
    WHERE 
        actor_rank <= 5
)
SELECT 
    t.production_year,
    STRING_AGG(t.movie_title, ', ') AS top_movies,
    SUM(COALESCE(t.total_actors, 0)) AS total_actors_count
FROM 
    TopMovies t
GROUP BY 
    t.production_year
ORDER BY 
    t.production_year DESC;

WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        co.name AS company_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        m.production_year
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, co.name, m.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.company_name,
    COALESCE(md.keywords, ARRAY[]::text[]) AS keywords_list
FROM 
    MovieDetails md
WHERE 
    EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = md.movie_id 
        AND ci.nr_order = 1
    )
ORDER BY 
    md.production_year DESC;
