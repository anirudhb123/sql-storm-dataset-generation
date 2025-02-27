WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoGrouped AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywordAggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        c.cast_count,
        c.cast_names,
        k.keywords
    FROM 
        RankedTitles mt
    JOIN 
        CastInfoGrouped c ON mt.title_id = c.movie_id
    LEFT JOIN 
        MovieKeywordAggregation k ON mt.title_id = k.movie_id
)
SELECT 
    d.title,
    d.production_year,
    d.cast_count,
    d.cast_names,
    d.keywords
FROM 
    MovieDetails d
WHERE 
    d.production_year >= 2000
ORDER BY 
    d.production_year DESC,
    d.title;
