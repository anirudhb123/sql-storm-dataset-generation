WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
BestMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        companies,
        keywords,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    bm.title,
    bm.production_year,
    bm.companies,
    bm.keywords,
    bm.cast_count
FROM 
    BestMovies bm
WHERE 
    bm.rank <= 10
ORDER BY 
    bm.rank;
