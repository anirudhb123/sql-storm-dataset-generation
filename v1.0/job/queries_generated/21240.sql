WITH RecursiveMovieInfo AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    WHERE m.production_year IS NOT NULL
    GROUP BY m.id
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        movie_title,
        production_year,
        keyword_count,
        CASE 
            WHEN production_year < 2000 THEN 'Classic'
            WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM RecursiveMovieInfo
    WHERE keyword_count > 0
),
ActorCount AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.id
),
TopActors AS (
    SELECT 
        actor_id, 
        actor_name,
        movies_count,
        DENSE_RANK() OVER (ORDER BY movies_count DESC) AS rank
    FROM ActorCount
    WHERE movies_count > 1
),
MovieEraDistribution AS (
    SELECT 
        era,
        COUNT(*) AS movie_count
    FROM FilteredMovies
    GROUP BY era
),
MoviesWithActors AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        ta.actor_name,
        ta.movies_count
    FROM FilteredMovies fm
    JOIN cast_info ci ON fm.movie_id = ci.movie_id
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN TopActors ta ON an.id = ta.actor_id
),
MovieKeywords AS (
    SELECT 
        m.movie_title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM FilteredMovies m
    LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.movie_title
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.era,
    ta.actor_name,
    ta.movies_count,
    mk.keywords,
    CASE 
        WHEN ta.movies_count > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Actor'
    END AS actor_category
FROM MoviesWithActors fm
JOIN TopActors ta ON fm.actor_name = ta.actor_name
JOIN MovieKeywords mk ON fm.movie_title = mk.movie_title
WHERE fm.production_year IS NOT NULL
  AND (fm.era = 'Classic' OR fm.era = 'Modern' OR mk.keywords IS NOT NULL)
ORDER BY fm.production_year DESC, ta.movies_count ASC;
