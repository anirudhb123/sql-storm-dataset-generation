WITH RecursiveActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak 
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
),
ActorMovieStats AS (
    SELECT 
        a.actor_id,
        a.actor_name,
        COALESCE(m.movie_count, 0) AS movie_count,
        RANK() OVER (ORDER BY COALESCE(m.movie_count, 0) DESC) AS rank,
        json_agg(dm.title) AS movies
    FROM 
        RecursiveActors a
    LEFT JOIN 
        (SELECT 
            ci.person_id,
            COUNT(DISTINCT ci.movie_id) AS movie_count
        FROM 
            cast_info ci
        GROUP BY 
            ci.person_id) m ON a.actor_id = m.person_id
    LEFT JOIN 
        (SELECT 
            ci.person_id,
            t.title
        FROM 
            cast_info ci
        JOIN 
            aka_title t ON ci.movie_id = t.id) dm ON a.actor_id = dm.person_id
    GROUP BY 
        a.actor_id, a.actor_name
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        keyword,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS movie_ranking
    FROM 
        MoviesWithKeywords m
    LEFT JOIN 
        movie_companies mc ON m.title = mc.note -- Assume title has notes or keywords
    GROUP BY 
        title, production_year, keyword
)

SELECT 
    a.actor_name,
    SUM(CASE WHEN t.rank <= 5 THEN 1 ELSE 0 END) AS top_movie_appearances,
    ARRAY_AGG(DISTINCT m.title) AS titles_from_top_movies,
    MAX(COALESCE(NULLIF(a.movie_count, 0), 1)) AS effective_movie_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS all_keywords
FROM 
    ActorMovieStats a 
LEFT JOIN 
    TopMovies t ON a.actor_name = t.title
LEFT JOIN 
    MoviesWithKeywords mk ON t.title = mk.title
GROUP BY 
    a.actor_name
ORDER BY 
    top_movie_appearances DESC, effective_movie_count DESC;
