WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_title ak ON m.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.id, m.title
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        cast_count,
        aka_names,
        keywords,
        companies,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, title) AS row_num
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.cast_count,
    fm.aka_names,
    fm.keywords,
    fm.companies
FROM 
    FilteredMovies fm
WHERE 
    fm.row_num <= 10
ORDER BY 
    fm.cast_count DESC;
