
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(cc.movie_id) AS total_movies,
        AVG(m.production_year) AS avg_year,
        LISTAGG(DISTINCT m.title, ', ') WITHIN GROUP (ORDER BY m.title) AS movies
    FROM 
        cast_info cc
    JOIN 
        aka_name a ON cc.person_id = a.person_id
    JOIN 
        aka_title m ON cc.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        a.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    pm.title AS movie_title,
    pm.production_year,
    a.person_id,
    a.movies,
    ks.keywords,
    CASE 
        WHEN a.total_movies > 10 THEN 'Veteran Actor'
        ELSE 'Newcomer'
    END AS actor_category
FROM 
    PopularMovies pm
LEFT JOIN 
    ActorStats a ON pm.movie_id = a.person_id
LEFT JOIN 
    MovieKeywords ks ON pm.movie_id = ks.movie_id
WHERE 
    ks.keywords IS NOT NULL
ORDER BY 
    pm.production_year DESC, 
    pm.title;
