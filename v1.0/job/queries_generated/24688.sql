WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS role_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.title, a.production_year, a.id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.movie_id
    FROM 
        RankedMovies rm
    WHERE 
        rm.role_rank <= 3
),
MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        COUNT(*) AS total_actors
    FROM 
        FilteredMovies f
    LEFT JOIN 
        cast_info ci ON f.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        f.title, f.production_year
),
MovieKeywords AS (
    SELECT 
        title_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title, 
    md.production_year,
    COALESCE(md.actor_names, 'No actors') AS actor_names,
    MD.total_actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN md.total_actors > 0 THEN 'Diverse Cast'
        ELSE 'No Cast'
    END AS cast_description
FROM 
    MovieDetails md
LEFT JOIN 
    MovieKeywords mk ON md.movie_id = mk.title_id
WHERE 
    md.production_year IN (
        SELECT DISTINCT 
            b.production_year 
        FROM 
            aka_title b 
        WHERE 
            b.production_year IS NOT NULL 
            AND b.title NOT LIKE '%unreleased%'
    )
EXCEPT 
SELECT 
    mk.title, 
    mk.production_year,
    NULL AS actor_names,
    0 AS total_actors,
    NULL AS keywords,
    'Unknown Cast' AS cast_description
FROM 
    MovieKeywords mk
WHERE 
    mk.keywords IS NULL
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
