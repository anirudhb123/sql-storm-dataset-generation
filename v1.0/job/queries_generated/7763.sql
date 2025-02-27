WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id AND cn.country_code = 'USA'
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
MovieRanked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_within_year
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    cast_names,
    keywords
FROM 
    MovieRanked
WHERE 
    rank_within_year <= 10
ORDER BY 
    production_year DESC, total_cast DESC;
