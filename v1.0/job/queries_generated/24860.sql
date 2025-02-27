WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS movie_rank,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'None') AS keywords
    FROM 
        aka_title t
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT * 
    FROM RankedMovies 
    WHERE movie_rank <= 3
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        ac.actor_count,
        tm.keywords
    FROM 
        TopMovies tm
        JOIN ActorCount ac ON tm.title_id = ac.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_count,
    CASE 
        WHEN md.actor_count > 10 THEN 'Blockbuster'
        WHEN md.actor_count BETWEEN 5 AND 10 THEN 'Moderate Success'
        ELSE 'Underdog'
    END AS success_classification,
    CASE 
        WHEN md.keywords LIKE '%Action%' THEN 'Action Packed'
        WHEN md.keywords LIKE '%Comedy%' THEN 'Light Hearted'
        ELSE 'Genre Unknown'
    END AS genre_insight,
    COALESCE(NULLIF(ROUND(AVG(CASE WHEN year IS NOT NULL THEN year END), 2), 0), 'No Data') AS avg_year
FROM 
    MovieDetails md
    LEFT JOIN movie_info mi ON md.production_year = mi.production_year
    LEFT JOIN (
        SELECT DISTINCT EXTRACT(YEAR FROM CURRENT_DATE) AS year
        FROM title t
        WHERE t.production_year IS NOT NULL
    ) AS years ON TRUE
GROUP BY 
    md.movie_title, md.production_year, md.actor_count, md.keywords
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
