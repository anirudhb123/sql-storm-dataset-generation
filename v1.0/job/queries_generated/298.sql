WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS actor_name,
    COALESCE(ta.movie_count, 0) AS movie_count,
    mwk.keywords,
    CASE 
        WHEN rm.rank <= 3 THEN 'Top Rank'
        ELSE 'Lower Rank'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON ta.avg_production_year = rm.production_year
LEFT JOIN 
    MoviesWithKeywords mwk ON mwk.movie_id = rm.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
