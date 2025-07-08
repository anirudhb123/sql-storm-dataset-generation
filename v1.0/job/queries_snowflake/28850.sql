
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
Actors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        a.actor_name,
        a.actor_rank
    FROM 
        TopMovies tm
    JOIN 
        Actors a ON tm.movie_id = a.movie_id
    ORDER BY 
        tm.production_year DESC, tm.title, a.actor_rank
)
SELECT 
    ad.title,
    ad.production_year,
    LISTAGG(ad.actor_name, ', ') WITHIN GROUP (ORDER BY ad.actor_rank) AS actors
FROM 
    ActorDetails ad
GROUP BY 
    ad.title, ad.production_year
ORDER BY 
    ad.production_year DESC, ad.title;
