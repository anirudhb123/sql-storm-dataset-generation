WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        p.gender AS actor_gender,
        ci.nr_order AS cast_order
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.id
    WHERE 
        t.production_year > 2000
        AND p.gender = 'F'
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        movie_keyword,
        actor_name,
        actor_gender,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind_id ORDER BY cast_order) AS rn
    FROM 
        MovieDetails
)
SELECT 
    production_year,
    kind_id,
    COUNT(*) AS total_movies,
    LISTAGG(actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actors_list,
    LISTAGG(movie_keyword, ', ') AS keyword_list
FROM 
    RankedMovies
WHERE 
    rn <= 5
GROUP BY 
    production_year, kind_id
ORDER BY 
    production_year DESC, total_movies DESC;
