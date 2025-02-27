WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

PopularActors AS (
    SELECT 
        c.person_id,
        ak.name,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.person_id, ak.name
    HAVING 
        COUNT(DISTINCT m.movie_id) > 5
),

MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ak.name AS actor_name,
        tk.kind AS title_kind,
        COUNT(DISTINCT kh.keyword) AS keyword_count,
        COALESCE(prt.role, 'Unknown') AS primary_role
    FROM 
        RankedMovies m
    LEFT JOIN 
        cast_info c ON c.movie_id = m.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        kind_type tk ON tk.id = m.kind_id
    LEFT JOIN 
        movie_keyword kh ON kh.movie_id = m.movie_id
    LEFT JOIN 
        role_type prt ON prt.id = c.role_id
    WHERE 
        m.rank_per_year <= 3  -- limiting to top 3 movies per year
    GROUP BY 
        m.movie_id, m.title, m.production_year, ak.name, tk.kind, prt.role
),

FinalOutput AS (
    SELECT 
        md.*,
        CASE 
            WHEN md.keyword_count > 5 THEN 'Trending'
            WHEN md.primary_role IS NULL THEN 'Unattributed'
            ELSE 'Classic'
        END AS movie_status
    FROM 
        MovieDetails md
)

SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.actor_name,
    fo.title_kind,
    fo.keyword_count,
    fo.movie_status
FROM 
    FinalOutput fo
WHERE 
    fo.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fo.production_year DESC,
    fo.title ASC;

-- The following logic will ensure we only get movies that either have trending keywords
-- or have a status of 'Unattributed' based on our complex conditions.
