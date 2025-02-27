WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM t.production_year) ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        ak.id AS aka_id,
        ak.name,
        ci.movie_id,
        ci.person_role_id,
        ci.nr_order,
        CASE 
            WHEN ci.nr_order IS NULL THEN 'NO_ORDER'
            WHEN ci.nr_order <= 3 THEN 'MAIN_ROLE'
            ELSE 'SUPPORTING_ROLE'
        END AS role_category
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(k.id) >= 2
),
FinalResults AS (
    SELECT 
        rt.title,
        rt.production_year,
        fa.name AS actor_name,
        fa.role_category,
        COALESCE(tk.keywords_list, 'NO_KEYWORDS') AS keywords
    FROM 
        RankedTitles rt
    LEFT JOIN 
        FilteredActors fa ON rt.title_id = fa.movie_id
    LEFT JOIN 
        TopKeywords tk ON rt.title_id = tk.movie_id
)
SELECT 
    title,
    production_year,
    actor_name,
    role_category,
    keywords
FROM 
    FinalResults
WHERE 
    production_year > 2000
    AND (role_category = 'MAIN_ROLE' OR keywords != 'NO_KEYWORDS')
ORDER BY 
    production_year DESC, 
    title ASC
LIMIT 50;

WITH MovieStatistics AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(nt.rating) AS avg_rating
    FROM 
        cast_info ci
    LEFT JOIN 
        (SELECT movie_id, rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) nt ON ci.movie_id = nt.movie_id
    GROUP BY 
        movie_id
),
HighlyRatedMovies AS (
    SELECT 
        movie_id
    FROM 
        MovieStatistics
    WHERE 
        avg_rating >= 8.0
)
SELECT 
    t.title,
    ms.actor_count
FROM 
    title t
JOIN 
    HighlyRatedMovies hr ON t.id = hr.movie_id
ORDER BY 
    actor_count DESC
LIMIT 10;
