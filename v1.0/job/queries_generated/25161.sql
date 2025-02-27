WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
), 

DirectorInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS director_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'Director'
    GROUP BY 
        ci.movie_id
),

DetailedMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        di.director_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorInfo di ON rm.movie_id = di.movie_id
)

SELECT 
    title.movie_title,
    title.production_year,
    title.movie_keyword,
    COALESCE(director_count, 0) AS director_count
FROM 
    DetailedMovies title
WHERE 
    title.rank = 1
ORDER BY 
    title.production_year DESC, 
    title.movie_title ASC
LIMIT 10;
