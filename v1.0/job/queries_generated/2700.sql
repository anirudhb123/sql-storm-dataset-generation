WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (
            SELECT 
                id 
            FROM kind_type 
            WHERE kind = 'movie'
        )
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    COALESCE(ci.company_count, 0) AS company_count
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC,
    md.title;
