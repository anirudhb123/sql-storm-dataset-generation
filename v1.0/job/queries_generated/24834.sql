WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
CompanyMovieCount AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
),
TopActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        ac.movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCount ac ON ak.person_id = ac.person_id
    WHERE 
        ac.movie_count > (
            SELECT 
                AVG(movie_count)
            FROM 
                ActorMovieCount
        )
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
    rm.title,
    rm.production_year,
    ta.name AS actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cmc.total_movies, 0) AS company_movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON EXISTS (
        SELECT 
            1 
        FROM 
            cast_info c 
        WHERE 
            c.movie_id = rm.movie_id AND c.person_id = ta.person_id
    )
LEFT JOIN 
    movie_companies mc ON mc.movie_id = rm.movie_id
LEFT JOIN 
    CompanyMovieCount cmc ON mc.company_id = cmc.company_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
WHERE 
    rm.rn <= 5 -- Filter to the top 5 latest movies per production year
ORDER BY 
    rm.production_year DESC, 
    ta.name;

