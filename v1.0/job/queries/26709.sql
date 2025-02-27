WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieRanks AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        RankedMovies
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.cast_count,
    mr.rank_within_year,
    mr.aka_names,
    mr.movie_keywords
FROM 
    MovieRanks mr
WHERE 
    mr.rank_within_year <= 5
ORDER BY 
    mr.production_year DESC, 
    mr.cast_count DESC;
