WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorFilmCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS film_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        afc.film_count
    FROM 
        aka_name a
    JOIN 
        ActorFilmCounts afc ON a.person_id = afc.person_id
    WHERE 
        afc.film_count > (
            SELECT 
                AVG(film_count)
            FROM 
                ActorFilmCounts
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
    tm.title,
    tm.production_year,
    ta.name AS top_actor,
    COALESCE(mk.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN LENGTH(mk.keywords) - LENGTH(REPLACE(mk.keywords, ',', '')) + 1
        ELSE 0
    END AS keyword_count,
    ROW_NUMBER() OVER (ORDER BY tm.production_year DESC) AS movie_rank
FROM 
    RankedMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
JOIN 
    TopActors ta ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = tm.title_id 
        AND ci.person_id = ta.person_id
    )
WHERE 
    tm.rank_year <= 10  
ORDER BY 
    tm.production_year DESC,
    keyword_count DESC;