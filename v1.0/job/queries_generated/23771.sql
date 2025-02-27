WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC NULLS LAST) AS rn,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id, title, production_year, cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
MovieDetails AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ' ORDER BY ak.name) AS actor_names,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ', ' ORDER BY kw.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.title_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.title_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.title_id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY 
        tm.title_id, tm.title, tm.production_year
),
FilteredDetails AS (
    SELECT
        md.title,
        md.production_year,
        md.actor_names,
        md.company_names,
        md.keywords
    FROM 
        MovieDetails md
    WHERE 
        -- bizarre NULL logic:
        (md.actor_names IS NOT NULL OR md.company_names IS NOT NULL OR md.keywords IS NOT NULL)
        AND (md.title LIKE '%Life%' OR md.title LIKE '%Dream%' OR md.keywords ILIKE '%fantasy%')
)
SELECT 
    title,
    production_year,
    actor_names,
    company_names,
    keywords,
    CASE 
        WHEN actor_names IS NOT NULL THEN 'Actors Present'
        ELSE 'No Actors'
    END AS actor_status,
    COUNT(*) OVER () AS total_movies
FROM 
    FilteredDetails
ORDER BY 
    production_year DESC, title ASC;
