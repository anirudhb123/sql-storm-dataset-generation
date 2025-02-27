WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = rm.movie_title AND at.production_year = rm.production_year LIMIT 1)
    GROUP BY 
        rm.movie_title, rm.production_year
),
TopMovies AS (
    SELECT 
        mwk.movie_title,
        mwk.production_year,
        mwk.keyword_count,
        ROW_NUMBER() OVER (ORDER BY mwk.keyword_count DESC) AS rank
    FROM 
        MoviesWithKeywords mwk
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.keyword_count,
    ak.name AS actor_name
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON ci.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = tm.movie_title AND at.production_year = tm.production_year LIMIT 1)
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.keyword_count DESC, tm.production_year ASC;
