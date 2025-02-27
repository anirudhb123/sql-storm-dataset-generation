
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieRanks AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        cast_count,
        aka_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    mr.rank,
    mr.title,
    mr.production_year,
    mr.cast_count,
    mr.aka_names,
    mr.keywords,
    CONCAT('Rank ', mr.rank, ': "', mr.title, '" has ', mr.cast_count, ' cast members, with alternate names: ', mr.aka_names) AS detailed_description
FROM 
    MovieRanks mr
WHERE 
    mr.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mr.rank
LIMIT 10;
