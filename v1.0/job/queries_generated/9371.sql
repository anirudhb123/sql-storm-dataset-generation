WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.kind_id, 
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        a.id
), MovieStats AS (
    SELECT 
        rm.title,
        rm.production_year,
        kt.kind AS movie_type,
        rm.num_cast_members,
        COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
    FROM 
        RankedMovies rm
    JOIN 
        kind_type kt ON rm.kind_id = kt.id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON rm.movie_id = mk.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.movie_type,
    ms.num_cast_members,
    ms.movie_keywords 
FROM 
    MovieStats ms
WHERE 
    ms.production_year > 2000
ORDER BY 
    ms.num_cast_members DESC, ms.production_year ASC;
