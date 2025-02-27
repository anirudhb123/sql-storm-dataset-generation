WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year, 
        r.keyword_count
    FROM 
        RankedMovies r
    WHERE 
        r.rank_per_year <= 3
),
ActorMovieCount AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_note
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        p.person_id
),
ActorAwardCounts AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT mc.movie_id) AS award_count
    FROM 
        movie_companies mc
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        mc.note LIKE '%award%'
    GROUP BY 
        p.person_id
),
FinalReport AS (
    SELECT 
        a.person_id,
        an.name AS actor_name,
        COUNT(DISTINCT am.movie_id) AS movies_appeared_in,
        COALESCE(ac.total_movies, 0) AS total_movies,
        COALESCE(ac.movies_with_note, 0) AS movies_with_note,
        COALESCE(aw.award_count, 0) AS award_count,
        STRING_AGG(DISTINCT tm.title, ', ') AS top_movies
    FROM 
        aka_name an
    LEFT JOIN 
        cast_info am ON an.person_id = am.person_id
    LEFT JOIN 
        ActorMovieCount ac ON an.person_id = ac.person_id
    LEFT JOIN 
        ActorAwardCounts aw ON an.person_id = aw.person_id
    LEFT JOIN 
        TopMovies tm ON am.movie_id = tm.movie_id
    GROUP BY 
        a.person_id, an.name
)
SELECT 
    person_id,
    actor_name,
    movies_appeared_in,
    total_movies,
    movies_with_note,
    award_count,
    CASE 
        WHEN total_movies > 10 THEN 'Prolific Actor'
        WHEN total_movies BETWEEN 5 AND 10 THEN 'Moderate Actor'
        ELSE 'Emerging Actor'
    END AS actor_category,
    CASE 
        WHEN award_count = 0 THEN 'No awards'
        ELSE CONCAT(award_count, ' awards')
    END AS awards_info,
    CASE 
        WHEN movies_with_note > 0 THEN 'Has notes in movies'
        ELSE 'No notes found'
    END AS notes_info
FROM 
    FinalReport
WHERE 
    movies_appeared_in > 5
ORDER BY 
    total_movies DESC, actor_name
LIMIT 100;
This complex SQL query contains multiple CTEs (Common Table Expressions), including logic for ranking movies, counting movie appearances by actors, tracking awards, and defining categories. It uses window functions, outer joins, aggregation with conditional logic, and incorporates string expressions, while ensuring that it addresses potential NULL values with COALESCE where appropriate. The final output classifies actors based on their movie counts and awards, providing a rich statistical view for benchmarking movie industry-related performance.
