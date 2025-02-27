WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id
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
        rank <= 10
),
ActorMovieCount AS (
    SELECT 
        ka.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    JOIN TopMovies tm ON ci.movie_id = tm.title
    GROUP BY 
        ka.name
)
SELECT 
    am.actor_name,
    am.movie_count,
    CASE 
        WHEN am.movie_count > 5 THEN 'Prolific'
        WHEN am.movie_count BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Occasional'
    END AS activity_level,
    COALESCE((
        SELECT 
            STRING_AGG(DISTINCT k.keyword, ', ') 
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            mk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = am.actor_name)
    ), 'No Keywords') AS keywords
FROM 
    ActorMovieCount am
ORDER BY 
    am.movie_count DESC;
