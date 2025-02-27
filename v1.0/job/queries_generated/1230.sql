WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        ac.movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCounts ac ON ak.person_id = ac.person_id
    WHERE 
        ac.movie_count > 5
),
MoviesWithKeywords AS (
    SELECT 
        t.title AS movie_title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    ta.name AS actor_name,
    ta.movie_count,
    mwk.keywords
FROM 
    RankedTitles tt
LEFT JOIN 
    TopActors ta ON ta.movie_count > 5
LEFT JOIN 
    MoviesWithKeywords mwk ON mwk.movie_title LIKE '%' || tt.title || '%'
WHERE 
    tt.title_rank = 1
ORDER BY 
    tt.production_year DESC, 
    ta.name;
