WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
DistinctRoles AS (
    SELECT DISTINCT 
        ci.role_id,
        rt.role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieDetails AS (
    SELECT 
        mt.title, 
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count,
        mt.production_year
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.title, mt.production_year
),
SelectedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.keyword_count,
        COALESCE(md.company_names, 'No companies') AS company_names,
        COALESCE(md.actor_names, 'No actors') AS actor_names
    FROM 
        MovieDetails md
    WHERE 
        md.keyword_count > 0 
        AND md.production_year IN (2021, 2022, 2023)
),
MaxProductionYear AS (
    SELECT 
        MAX(production_year) AS max_year
    FROM 
        SelectedMovies
)
SELECT 
    sm.title,
    sm.production_year,
    sm.keyword_count,
    sm.company_names,
    sm.actor_names,
    CASE 
        WHEN sm.production_year = mp.max_year THEN 'Latest Release'
        ELSE 'Previous Release'
    END AS release_type,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = sm.title LIMIT 1)) AS total_cast
FROM 
    SelectedMovies sm
CROSS JOIN 
    MaxProductionYear mp
ORDER BY 
    sm.production_year DESC,
    sm.keyword_count DESC;

-- Additional complexity
WITH MovieActors AS (
    SELECT 
        at.title,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
ParentChildConnections AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        lt.link AS link_type
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        lt.link IS NOT NULL
)
SELECT 
    ma.title AS movie_title,
    ma.name AS actor_name,
    (SELECT COUNT(*) FROM ParentChildConnections pcc WHERE pcc.movie_id = ma.movie_id) AS linked_movies_count,
    CASE 
        WHEN ma.actor_rank = 1 THEN 'Lead Actor'
        WHEN ma.actor_rank <= 3 THEN 'Supporting Actor'
        ELSE 'Minor Role'
    END AS role_type
FROM 
    MovieActors ma
WHERE 
    ma.actor_rank <= 5
ORDER BY 
    ma.title, ma.actor_rank;
