WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(ci.id) DESC) AS rank_by_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    p.name AS popular_actor,
    pa.movie_count AS actor_movies,
    tk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON rm.cast_count = pa.movie_count
LEFT JOIN 
    TitleKeywords tk ON rm.movie_id = tk.movie_id
LEFT JOIN 
    aka_name p ON p.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = rm.movie_id)
WHERE 
    rm.rank_by_cast <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
