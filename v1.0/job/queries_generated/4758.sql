WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
TopActors AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY COUNT(*) DESC) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id, ak.name
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ta.actor_name
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopActors ta ON rm.movie_id = ta.movie_id
    WHERE 
        ta.actor_rank = 1 OR ta.actor_rank IS NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mwa.title,
    mwa.production_year,
    COALESCE(mwa.actor_name, 'No Actor') AS lead_actor,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    MoviesWithActors mwa
LEFT JOIN 
    MovieKeywords mk ON mwa.movie_id = mk.movie_id
WHERE 
    mwa.year_rank <= 5
ORDER BY 
    mwa.production_year DESC, mwa.title ASC;
