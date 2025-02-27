WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.aka_names,
        ms.keywords,
        RANK() OVER (ORDER BY ms.cast_count DESC) AS rank_by_cast
    FROM 
        MovieStats AS ms
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    rm.keywords
FROM 
    RankedMovies AS rm
WHERE 
    rm.rank_by_cast <= 10
ORDER BY 
    rm.rank_by_cast;
