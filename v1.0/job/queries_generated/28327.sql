WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS alias_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS cc ON cc.movie_id = t.id
    JOIN 
        aka_name AS ak ON ak.person_id = cc.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighestCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        alias_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    hcm.alias_names,
    hcm.keywords
FROM 
    HighestCastMovies AS hcm
WHERE 
    hcm.rank <= 10
ORDER BY 
    hcm.cast_count DESC, 
    hcm.production_year DESC;
