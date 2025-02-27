WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        fm.actor_name,
        fm.movie_title,
        fm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT movie_id 
                                            FROM aka_title 
                                            WHERE title = fm.movie_title 
                                            LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.actor_name, fm.movie_title, fm.production_year
),
ActorInfo AS (
    SELECT 
        an.person_id,
        an.name,
        pi.info
    FROM 
        aka_name an
    LEFT JOIN 
        person_info pi ON an.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
)
SELECT 
    a.actor_name,
    a.movie_title,
    a.production_year,
    COALESCE(a.keywords, 'No keywords available') AS keywords,
    ai.info AS actor_birthdate
FROM 
    MoviesWithKeywords a
LEFT JOIN 
    ActorInfo ai ON a.actor_name = ai.name
WHERE 
    a.production_year >= (
        SELECT 
            AVG(production_year) 
        FROM 
            aka_title 
        WHERE 
            production_year IS NOT NULL
    )
  AND
    (ai.info IS NULL OR ai.info IS NOT NULL)
ORDER BY 
    a.production_year DESC;
