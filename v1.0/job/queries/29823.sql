WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        TopRankedMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = tm.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.company_names,
        CASE 
            WHEN md.cast_count > 10 THEN 'Large Cast'
            WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        MovieDetails md
)

SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.cast_count,
    fo.company_names,
    fo.cast_size
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC, 
    fo.cast_count DESC;
