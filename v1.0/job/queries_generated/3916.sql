WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id
), 
CompanyStats AS (
    SELECT 
        mc.movie_id, 
        COUNT(mc.company_id) AS company_count, 
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year, 
        md.keywords, 
        md.cast_count,
        cs.company_count,
        cs.company_names,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyStats cs ON md.movie_id = cs.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.cast_count,
    COALESCE(tm.company_count, 0) AS company_count,
    COALESCE(tm.company_names, 'None') AS company_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10 
    AND (tm.production_year IS NULL OR tm.production_year >= 2000)
ORDER BY 
    tm.rank;
