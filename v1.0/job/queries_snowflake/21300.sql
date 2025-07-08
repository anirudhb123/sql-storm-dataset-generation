
WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastByRole AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL OR ci.note NOT LIKE '%uncredited%'
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
ComplexJoin AS (
    SELECT 
        r.title,
        c.person_id,
        c.role,
        mk.keywords,
        COUNT(mk.keywords) OVER (PARTITION BY r.title) AS keyword_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        CastByRole c ON r.title_id = c.movie_id AND c.role_rank = 1
    LEFT JOIN 
        MoviesWithKeywords mk ON r.title_id = mk.movie_id
    WHERE 
        r.year_rank = 1
)
SELECT 
    cj.title,
    COUNT(DISTINCT cj.person_id) AS total_actors,
    MAX(COALESCE(cj.keywords, 'No Keywords')) AS keywords,
    SUM(CASE WHEN cj.role IN ('Director', 'Producer') THEN 1 ELSE 0 END) AS key_roles_count,
    ARRAY_AGG(DISTINCT cj.role) AS all_roles
FROM 
    ComplexJoin cj
GROUP BY 
    cj.title
ORDER BY 
    total_actors DESC
LIMIT 10 OFFSET 5;
