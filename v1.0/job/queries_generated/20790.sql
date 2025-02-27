WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS rn
    FROM 
        aka_title t
    WHERE 
        t.note IS NULL 
        OR t.note <> 'N/A'
), 
DistinctCompanies AS (
    SELECT 
        DISTINCT c.name AS company_name,
        c.country_code
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    WHERE 
        mc.note IS NULL 
        OR mc.note <> 'CONFIDENTIAL'
),
PersonRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
), 
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
          AND (k.keyword IS NULL OR LENGTH(k.keyword) < 5)
), 
FinalOutput AS (
    SELECT 
        p.person_id,
        a.name AS actor_name,
        COALESCE(c.company_name, 'Independent') AS company_name,
        f.movie_id,
        f.title AS movie_title,
        f.production_year,
        f.keyword,
        COUNT(rc.movie_count) AS total_movies,
        MAX(rc.has_note) AS any_note
    FROM 
        aka_name a
    JOIN 
        PersonRoleCounts rc ON a.person_id = rc.person_id
    JOIN 
        cast_info ci ON ci.person_id = a.person_id
    LEFT JOIN 
        DistinctCompanies c ON c.company_name LIKE '%' || a.name || '%'
    JOIN 
        FilteredMovies f ON f.movie_id = ci.movie_id
    WHERE 
        rc.movie_count > 0
    GROUP BY 
        p.person_id, a.name, c.company_name, f.movie_id, f.title, f.production_year, f.keyword
    HAVING 
        MAX(rc.has_note) = 1
    ORDER BY 
        f.production_year DESC, total_movies DESC
)
SELECT 
    'Performance Benchmark Data' AS benchmark_title,
    f.actor_name,
    f.movie_title,
    f.production_year,
    f.keyword,
    NULLIF(f.company_name, 'Independent') AS verified_company
FROM 
    FinalOutput f
WHERE 
    f.movie_title IS NOT NULL
  AND f.production_year IS NOT NULL
  AND (f.keyword IS NOT NULL OR LENGTH(f.keyword) > 1)
ORDER BY 
    f.production_year, LENGTH(f.keyword), f.actor_name
LIMIT 50;
