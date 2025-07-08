
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        cn.country_code = 'USA' 
        AND t.production_year >= 2000
    GROUP BY 
        t.title, 
        t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.aka_names,
        rm.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tr.title,
    tr.production_year,
    tr.aka_names,
    tr.cast_count
FROM 
    TopRatedMovies tr
WHERE 
    tr.rank <= 10
ORDER BY 
    tr.rank;
