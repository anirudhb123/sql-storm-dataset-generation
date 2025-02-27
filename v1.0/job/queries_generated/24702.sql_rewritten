WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MoviesOverview AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count,
        mk.keywords,
        COALESCE(NULLIF(rm.title_rank, 1), 2) AS title_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
),
FinalResults AS (
    SELECT 
        title,
        production_year,
        actor_count,
        keywords,
        CASE 
            WHEN actor_count IS NULL THEN 'No actors'
            WHEN title_rank <= 3 THEN 'Top Rank!'
            ELSE 'Regular Movie'
        END AS classification
    FROM 
        MoviesOverview
    WHERE 
        (actor_count > 5 OR keywords IS NOT NULL)
    ORDER BY 
        production_year DESC,
        title_rank ASC
)
SELECT 
    title, 
    production_year, 
    actor_count, 
    keywords, 
    classification
FROM 
    FinalResults
WHERE 
    NOT (keywords IS NULL AND actor_count < 5)
    OR (keywords IS NOT NULL AND actor_count IS NULL);