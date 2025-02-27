WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title AS mt
    JOIN 
        cast_info AS ci ON mt.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.id) > 1
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        COALESCE(pkw.keyword, 'No Keywords') AS popular_keyword
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        PopularKeywords AS pkw ON rm.movie_id = pkw.movie_id
    ORDER BY 
        rm.actor_count DESC, rm.production_year DESC
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    md.popular_keyword
FROM 
    MovieDetails AS md
WHERE 
    md.actor_count > 2
LIMIT 10;
