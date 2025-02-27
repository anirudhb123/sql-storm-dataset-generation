WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COALESCE(mk.keyword, 'Unknown') AS keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
TopMoviesPerYear AS (
    SELECT 
        title,
        production_year,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        c.kind AS company_kind,
        ARRAY_AGG(DISTINCT ci.role_id) AS role_ids,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.title, m.production_year, c.kind
),
FinalBenchmark AS (
    SELECT 
        d.title,
        d.production_year,
        d.company_kind,
        d.total_cast,
        COALESCE(td.keyword, 'N/A') AS keyword,
        CASE 
            WHEN d.total_cast = 0 THEN 'No Cast'
            WHEN d.total_cast < 5 THEN 'Few Cast'
            ELSE 'Many Cast'
        END AS cast_size_group
    FROM 
        MovieDetails d
    LEFT JOIN 
        TopMoviesPerYear td ON d.title = td.title AND d.production_year = td.production_year
    WHERE 
        d.company_kind IS NOT NULL
)

SELECT 
    CAST(d.production_year AS TEXT) AS year,
    STRING_AGG(d.title, '; ') AS titles,
    STRING_AGG(DISTINCT d.company_kind, ', ') AS company_kinds,
    SUM(d.total_cast) AS total_cast,
    COUNT(d.keyword) AS keyword_count,
    COUNT(*) FILTER (WHERE d.cast_size_group = 'No Cast') AS no_cast_count,
    COUNT(*) FILTER (WHERE d.cast_size_group = 'Few Cast') AS few_cast_count,
    COUNT(*) FILTER (WHERE d.cast_size_group = 'Many Cast') AS many_cast_count
FROM 
    FinalBenchmark d
GROUP BY 
    d.production_year
ORDER BY 
    d.production_year DESC;
