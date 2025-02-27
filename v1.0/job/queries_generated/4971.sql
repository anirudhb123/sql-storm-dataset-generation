WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        json_agg(DISTINCT ak.name) AS aka_names,
        json_agg(DISTINCT cn.name) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        aka_name ak ON tm.movie_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.aka_names, '[]') AS aka_names,
    COALESCE(md.companies, '[]') AS companies,
    EXISTS (
        SELECT 
            1 
        FROM 
            movie_info mi 
        WHERE 
            mi.movie_id = md.movie_id 
            AND mi.info ILIKE '%Award%'
    ) AS has_award_info
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title;
