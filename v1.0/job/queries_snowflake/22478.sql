
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
AggregateMovies AS (
    SELECT 
        ct.id AS company_type_id,
        ct.kind,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        company_type ct
    LEFT JOIN 
        movie_companies mc ON ct.id = mc.company_type_id
    LEFT JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        ct.id, ct.kind
),
CastInfoRanked AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year > 2000
    GROUP BY 
        at.title, at.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    r.title AS title_name,
    r.production_year,
    COALESCE(f.total_cast, 0) AS total_cast,
    a.movie_count AS company_type_movie_count,
    a.avg_production_year
FROM 
    RankedTitles r
LEFT JOIN 
    FilteredMovies f ON r.title = f.title AND r.production_year = f.production_year
LEFT JOIN 
    AggregateMovies a ON a.movie_count = (
        SELECT MAX(movie_count) FROM AggregateMovies
    )
WHERE 
    r.title_id IN (
        SELECT movie_id 
        FROM CastInfoRanked 
        WHERE role_rank = 1
    )
    OR r.production_year IS NULL
ORDER BY 
    r.production_year DESC, r.title;
