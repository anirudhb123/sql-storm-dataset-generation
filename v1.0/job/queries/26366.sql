WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),

FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        STRING_AGG(rm.actor_name, ', ' ORDER BY rm.actor_rank) AS actors_list
    FROM 
        RankedMovies rm
    GROUP BY 
        rm.movie_title, rm.production_year
),

MoviesWithKeywords AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        k.keyword
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON fm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actors_list,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MoviesWithKeywords kw ON fm.movie_title = kw.movie_title AND fm.production_year = kw.production_year
GROUP BY 
    fm.movie_title, fm.production_year, fm.actors_list
ORDER BY 
    fm.production_year DESC, fm.movie_title;
