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
FilteredActors AS (
    SELECT 
        c.person_id,
        a.name,
        COUNT(DISTINCT cm.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') -- Budget information presumed
    WHERE 
        a.name IS NOT NULL 
    GROUP BY 
        c.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
ActorMovieInfo AS (
    SELECT 
        f.name AS actor_name,
        r.movie_id,
        m.title AS movie_title,
        COALESCE(mk.all_keywords, 'No keywords') AS keywords,
        mi.info AS budget_info
    FROM 
        FilteredActors f
    JOIN 
        cast_info r ON r.person_id = f.person_id
    JOIN 
        RankedMovies m ON r.movie_id = m.movie_id
    LEFT JOIN 
        MoviesWithKeywords mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON r.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') -- Again assuming budget info
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keywords,
    budget_info
FROM 
    ActorMovieInfo
WHERE 
    production_year BETWEEN 2000 AND 2023
    AND (keywords IS NOT NULL OR budget_info IS NOT NULL)
ORDER BY 
    production_year ASC, actor_name DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY; -- Paginated results for performance benchmarking
