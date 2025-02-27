WITH RankedMovies AS (
    SELECT 
        tk.id AS title_id,
        tk.title,
        tk.production_year,
        ARRAY_AGG(DISTINCT kn.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title tk
    LEFT JOIN 
        movie_keyword mk ON tk.id = mk.movie_id
    LEFT JOIN 
        keyword kn ON mk.keyword_id = kn.id
    LEFT JOIN 
        cast_info ci ON tk.id = ci.movie_id
    GROUP BY 
        tk.id, tk.title, tk.production_year
),
FilteredMovies AS (
    SELECT 
        rm.*,
        RANK() OVER (ORDER BY rm.cast_count DESC, rm.production_year DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        keywords,
        rank,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY rank) AS year_rank
    FROM 
        FilteredMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.rank,
    tm.year_rank,
    ci.role_id,
    pi.info,
    cn.name AS company_name
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ci.nr_order IS NOT NULL
ORDER BY 
    tm.rank, tm.production_year DESC, ci.nr_order;
