WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        coalesce(mi.info, 'N/A') AS movie_info,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'imdb rating') 
    LEFT JOIN 
        movie_companies mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON rm.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.title_id, rm.title, rm.production_year, rm.cast_count, mi.info
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        movie_info,
        companies,
        keywords,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, cast_count DESC) AS overall_rank
    FROM 
        MovieDetails
    WHERE 
        cast_count > 0
)

SELECT 
    *,
    CASE 
        WHEN overall_rank <= 3 THEN 'Top'
        ELSE 'Not Top'
    END AS is_top,
    GREATEST(cast_count, LENGTH(companies) - LENGTH(REPLACE(companies, ',', '')) + 1) AS company_count
FROM 
    TopMovies
WHERE 
    movie_info IS NOT NULL
    AND (companies IS NULL OR LENGTH(companies) > 5)
ORDER BY 
    overall_rank;

