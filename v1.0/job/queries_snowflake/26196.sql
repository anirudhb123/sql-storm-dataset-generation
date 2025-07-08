
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        person_id,
        movie_count
    FROM 
        ActorMovieCount
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MovieInfoWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        LISTAGG(k.keyword, ',') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
),
CombinedResults AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        a.name AS actor_name,
        m.rank_by_title,
        mk.keywords
    FROM 
        RankedMovies m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        MovieInfoWithKeywords mk ON m.movie_id = mk.movie_id
    WHERE 
        c.person_id IN (SELECT person_id FROM TopActors)
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    rank_by_title,
    keywords
FROM 
    CombinedResults
WHERE 
    production_year > 2000
ORDER BY 
    production_year DESC, rank_by_title, actor_name;
