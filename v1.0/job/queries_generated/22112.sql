WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
TopMovies AS (
    SELECT 
        rm.*,
        mg.genres
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.title = mg.title
    WHERE 
        rm.rank_per_year = 1
)
SELECT 
    tm.title,
    COALESCE(NULLIF(tm.genres, ''), 'No Genres Found') AS genres,
    CASE 
        WHEN tm.actor_count = 0 THEN 'No Actors'
        ELSE tm.actor_count::text || ' Actor(s)'
    END AS actor_summary,
    (SELECT COUNT(*) 
     FROM movie_link ml 
     WHERE ml.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)) AS linked_movie_count,
    (
        SELECT 
            STRING_AGG(DISTINCT cn.name, ', ') 
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        WHERE 
            mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    ) AS production_companies
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.title;
