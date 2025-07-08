
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),

MovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS movie_info,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.total_cast, rm.cast_names
),

FinalRanking AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names,
        movie_info,
        keywords,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        MovieInfo
)

SELECT 
    rank,
    title,
    production_year,
    total_cast,
    cast_names,
    movie_info,
    keywords
FROM 
    FinalRanking
WHERE 
    rank <= 10
ORDER BY 
    rank;
