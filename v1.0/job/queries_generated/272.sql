WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COALESCE(COUNT(DISTINCT mc.id), 0) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.cast_names,
        md.company_count,
        rt.production_year,
        rt.rank
    FROM 
        MovieDetails md
    JOIN 
        RankedTitles rt ON md.movie_id = rt.title_id
    WHERE 
        md.company_count > 0
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_names,
    tm.company_count,
    CASE 
        WHEN tm.rank BETWEEN 1 AND 5 THEN 'Top 5'
        WHEN tm.rank BETWEEN 6 AND 10 THEN 'Rank 6-10'
        ELSE 'Other'
    END AS rank_category
FROM 
    TopMovies tm
WHERE 
    tm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    tm.production_year DESC, 
    tm.rank;
