WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),

ActorMovieInfo AS (
    SELECT 
        r.actor_name,
        r.movie_title,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        RankedTitles r
    LEFT JOIN 
        MovieKeywords mk ON r.movie_title = mk.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = r.movie_title
    GROUP BY 
        r.actor_name, r.movie_title, mk.keywords
),

FinalBenchmark AS (
    SELECT 
        ami.actor_name,
        ami.movie_title,
        ami.keywords,
        ami.actor_count,
        CASE 
            WHEN ami.actor_count IS NULL THEN 'Unknown'
            WHEN ami.actor_count > 5 THEN 'Ensemble Cast'
            WHEN ami.actor_count = 1 THEN 'Solo Performance'
            ELSE 'Various Actors'
        END AS cast_type
    FROM 
        ActorMovieInfo ami
)

SELECT 
    fb.actor_name,
    fb.movie_title,
    fb.keywords,
    fb.actor_count,
    fb.cast_type,
    CONCAT('This movie ', fb.movie_title, ' features ', fb.actor_count, ' actors!') AS movie_description
FROM 
    FinalBenchmark fb
WHERE 
    fb.actor_count > 0
ORDER BY 
    fb.actor_count DESC, 
    fb.movie_title ASC
FETCH FIRST 10 ROWS ONLY;
