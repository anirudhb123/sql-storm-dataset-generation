WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS rank_within_year
    FROM 
        aka_title t
        JOIN movie_companies m ON t.movie_id = m.movie_id
        LEFT JOIN aka_name ak ON ak.person_id IN (
            SELECT ci.person_id 
            FROM cast_info ci 
            WHERE ci.movie_id = t.movie_id
        )
    GROUP BY 
        t.id, t.title, t.production_year
),
TopPerformers AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
)
SELECT 
    tp.title,
    tp.production_year,
    tp.company_count,
    string_agg(DISTINCT ak.name, ', ') AS associated_ak_names
FROM 
    TopPerformers tp
    LEFT JOIN aka_title ak ON ak.movie_id = tp.movie_id
GROUP BY 
    tp.title, tp.production_year, tp.company_count
ORDER BY 
    tp.production_year DESC, tp.company_count DESC;
