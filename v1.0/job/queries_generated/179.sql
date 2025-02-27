WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT concat(co.name, ' (', ct.kind, ')'), ', ') AS company_details
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tm.production_year = (SELECT production_year FROM aka_title WHERE movie_id = mc.movie_id)
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        ak.name, tm.title, tm.production_year
)
SELECT 
    ad.actor_name,
    ad.title,
    ad.production_year,
    COALESCE(ad.company_details, 'No Companies') AS company_details
FROM 
    ActorDetails ad
WHERE
    ad.production_year IS NOT NULL
ORDER BY 
    ad.production_year DESC, 
    ad.actor_name ASC;
