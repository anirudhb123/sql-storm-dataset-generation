
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_kind,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind
),

TopMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_name,
        md.cast_kind,
        md.keywords,
        COUNT(*) OVER (PARTITION BY md.production_year) AS movie_count
    FROM 
        MovieDetails md
    WHERE 
        md.actor_rank <= 3
)

SELECT 
    CONCAT(tm.title, ' (', tm.production_year, ') - Starring: ', LISTAGG(DISTINCT tm.actor_name, ', ') WITHIN GROUP (ORDER BY tm.actor_name)) AS movie_info,
    tm.movie_count
FROM 
    TopMovies tm
GROUP BY 
    tm.title, tm.production_year, tm.movie_count
HAVING 
    COUNT(DISTINCT tm.actor_name) > 2
ORDER BY 
    tm.production_year DESC, tm.movie_count DESC;
