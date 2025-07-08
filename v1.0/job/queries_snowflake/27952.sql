
WITH RankedActors AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
),
MoviesWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        LISTAGG(DISTINCT k.keyword, ',') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keywords,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        MoviesWithInfo
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keywords,
    ra.actor_name AS top_actor
FROM 
    TopMovies tm
JOIN 
    RankedActors ra ON tm.movie_id = (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id = ra.person_id 
        ORDER BY nr_order 
        LIMIT 1
    )
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
