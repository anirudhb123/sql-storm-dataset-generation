WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.title ORDER BY a.name) AS actor_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        TopMovies m ON ci.movie_id = m.title_id
),
MovieKeywords AS (
    SELECT 
        m.title_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        TopMovies m ON mk.movie_id = m.title_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    GROUP BY 
        m.title_id
)

SELECT 
    m.title,
    m.production_year,
    a.actor_name,
    a.actor_order,
    COALESCE(k.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies m
LEFT JOIN 
    ActorInfo a ON m.title_id = a.title_id
LEFT JOIN 
    MovieKeywords k ON m.title_id = k.title_id
ORDER BY 
    m.production_year, m.title, a.actor_order;
