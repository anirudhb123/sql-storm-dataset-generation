
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        LISTAGG(actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actors
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actors,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(m.info, 'No Info') AS additional_info
FROM 
    FilteredMovies f
LEFT JOIN 
    (SELECT 
         mk.movie_id,
         LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
     FROM 
         movie_keyword mk
     JOIN 
         keyword k ON mk.keyword_id = k.id
     GROUP BY 
         mk.movie_id) k ON f.movie_id = k.movie_id
LEFT JOIN 
    (SELECT 
         mi.movie_id,
         LISTAGG(mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info
     FROM 
         movie_info mi
     GROUP BY 
         mi.movie_id) m ON f.movie_id = m.movie_id
ORDER BY 
    f.production_year DESC,
    f.movie_id;
