WITH MovieStats AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        c.kind AS cast_type,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        COALESCE(COUNT(DISTINCT mk.keyword_id), 0) AS keyword_count
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.person_id = t.id
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    WHERE 
        LOWER(a.name) LIKE 'jack%'
    GROUP BY 
        a.id, a.name, t.title, t.production_year, c.kind
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank_by_keyword
    FROM 
        MovieStats
)
SELECT 
    aka_name,
    movie_title,
    production_year,
    cast_type,
    cast_count,
    keyword_count,
    rank_by_cast,
    rank_by_keyword
FROM 
    RankedMovies
WHERE 
    rank_by_cast <= 5 OR rank_by_keyword <= 5
ORDER BY 
    production_year, rank_by_cast, rank_by_keyword;
