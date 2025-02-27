WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year >= 2000
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        c.kind AS company_type,
        array_agg(DISTINCT k.keyword) AS keywords,
        COALESCE(SUM(mvi.info::int), 0) AS vote_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mvi ON rm.movie_id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'votes')
    WHERE 
        rm.year_rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, c.kind
),
FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.company_type,
        tm.keywords,
        tm.vote_count
    FROM 
        TopMovies tm
    ORDER BY 
        tm.production_year DESC, tm.vote_count DESC
)
SELECT 
    f.title,
    f.production_year,
    f.company_type,
    f.keywords,
    f.vote_count
FROM 
    FinalOutput f
WHERE 
    f.vote_count > 100
LIMIT 10;
