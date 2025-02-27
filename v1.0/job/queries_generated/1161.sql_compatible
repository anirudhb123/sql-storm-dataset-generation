
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_within_year
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        a.name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) > 10
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword AS m
    JOIN 
        keyword AS k ON m.keyword_id = k.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(pa.movies_count, 0) AS popular_actors_count,
    STRING_AGG(mk.keyword, ', ') AS keywords,
    rm.cast_count
FROM 
    RankedMovies AS rm
LEFT JOIN 
    PopularActors AS pa ON pa.name IN (
        SELECT 
            a.name 
        FROM 
            aka_name AS a
        JOIN 
            cast_info AS ci ON ci.person_id = a.person_id 
        WHERE 
            ci.movie_id = rm.movie_id
    )
LEFT JOIN 
    MovieKeywords AS mk ON rm.movie_id = mk.movie_id AND mk.keyword_rank <= 3
WHERE 
    rm.rank_within_year <= 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, pa.movies_count, rm.cast_count
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
