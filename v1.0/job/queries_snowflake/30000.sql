WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_year
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL 
        AND at.production_year >= 2000
),
TitleMetrics AS (
    SELECT 
        at.id AS title_id,
        at.title,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = at.movie_id
    GROUP BY 
        at.id, at.title
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.total_actors,
        tm.total_keywords,
        rm.rank_year
    FROM 
        TitleMetrics tm
    JOIN 
        RankedMovies rm ON tm.title = rm.title
    WHERE 
        rm.rank_year <= 5
)
SELECT 
    fr.title,
    fr.total_actors,
    fr.total_keywords,
    fr.rank_year
FROM 
    FinalResults fr
ORDER BY 
    fr.rank_year DESC, 
    fr.total_actors DESC;
