WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id
),
MovieRanking AS (
    SELECT 
        title,
        production_year,
        total_cast,
        cast_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, production_year ASC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    rank,
    title,
    production_year,
    total_cast,
    cast_names,
    keywords
FROM 
    MovieRanking
WHERE 
    rank <= 10
ORDER BY 
    rank;
