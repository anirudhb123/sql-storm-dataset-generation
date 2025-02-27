WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title AS title,
        title.production_year,
        title.kind_id,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title ASC) AS title_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        cast_info.movie_id,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names
    FROM 
        cast_info
    JOIN 
        aka_name
    ON 
        cast_info.person_id = aka_name.person_id
    GROUP BY 
        cast_info.movie_id
),
MovieKeywords AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword
    ON 
        movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
),
MoviesWithDetails AS (
    SELECT 
        RankedTitles.title_id,
        RankedTitles.title,
        RankedTitles.production_year,
        CAST(COALESCE(CastDetails.actor_count, 0) AS INTEGER) AS actor_count,
        COALESCE(CastDetails.actor_names, 'None') AS actor_names,
        COALESCE(MovieKeywords.keywords, 'None') AS keywords
    FROM 
        RankedTitles
    LEFT JOIN 
        CastDetails
    ON 
        RankedTitles.title_id = CastDetails.movie_id
    LEFT JOIN 
        MovieKeywords
    ON 
        RankedTitles.title_id = MovieKeywords.movie_id
)
SELECT 
    title_id,
    title,
    production_year,
    actor_count,
    actor_names,
    keywords
FROM 
    MoviesWithDetails
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    title ASC;
