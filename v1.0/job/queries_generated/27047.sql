WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
TopMovies AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.cast_count,
        RANK() OVER(ORDER BY mwc.cast_count DESC) AS cast_rank
    FROM 
        MoviesWithCast mwc
    WHERE 
        mwc.production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    rn.name AS director_name,
    grp.kind AS genre,
    info.info AS movie_info
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    kind_type grp ON mc.company_type_id = grp.id
JOIN 
    movie_info info ON tm.movie_id = info.movie_id 
JOIN 
    role_type rt ON info.info_type_id = rt.id 
JOIN 
    name rn ON tn.person_id = rn.id 
WHERE 
    rt.role LIKE '%Director%'
    AND tm.cast_rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.production_year DESC;

