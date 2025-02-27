WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS all_actors
    FROM 
        aka_title AS t
    INNER JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    INNER JOIN 
        kind_type AS kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),

PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    INNER JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 5
),

FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.movie_kind,
        rm.cast_count,
        rm.all_actors,
        pk.keyword
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        PopularKeywords AS pk ON rm.movie_id = pk.movie_id
)

SELECT 
    movie_id,
    title,
    production_year,
    movie_kind,
    cast_count,
    all_actors,
    STRING_AGG(DISTINCT keyword, ', ') AS popular_keywords
FROM 
    FinalResults
GROUP BY 
    movie_id, title, production_year, movie_kind, cast_count, all_actors
ORDER BY 
    production_year DESC, cast_count DESC;
