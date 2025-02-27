WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS number_of_cast,
        COUNT(DISTINCT mi.info) AS number_of_infos
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.company_names, '{}') AS companies,
    COALESCE(md.keywords, '') AS keywords,
    md.number_of_cast,
    md.number_of_infos
FROM 
    MovieDetails md
WHERE 
    md.number_of_cast > 0
ORDER BY 
    md.production_year DESC, md.title;
