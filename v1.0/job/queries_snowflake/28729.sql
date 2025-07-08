
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender AS actor_gender,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT cc.id) AS cast_count
    FROM 
        aka_title AS t
    INNER JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    INNER JOIN 
        name AS p ON a.person_id = p.imdb_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    WHERE 
        t.production_year >= 2000
        AND p.gender = 'F'
    GROUP BY 
        t.id, t.title, t.production_year, a.name, p.gender
),
RankedMovies AS (
    SELECT 
        md.*, 
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank
    FROM 
        MovieDetails AS md
)
SELECT 
    rm.rank,
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.keywords,
    rm.cast_count
FROM 
    RankedMovies AS rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
