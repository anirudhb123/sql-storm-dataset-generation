WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        km.keyword AS associated_keyword,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title AS a
    JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN 
        keyword AS km ON mk.keyword_id = km.id
    LEFT JOIN 
        cast_info AS ci ON a.id = ci.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, km.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        associated_keyword,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        associated_keyword IS NOT NULL
)
SELECT 
    tm.movie_title,
    tm.production_year,
    kt.kind AS movie_kind,
    tm.associated_keyword,
    tm.cast_count,
    pt.info AS production_info
FROM 
    TopMovies AS tm
JOIN 
    kind_type AS kt ON tm.kind_id = kt.id
JOIN 
    movie_info AS mi ON tm.movie_title = mi.info
JOIN 
    person_info AS pt ON pt.person_id IN (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = tm.movie_id
    )
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
