WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COALESCE(b.name, 'Unknown') AS director_name,
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name b ON mc.company_id = b.id AND b.country_code = 'USA'
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%feature%')
        AND a.production_year IS NOT NULL
),

ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MoviesWithKeywords AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.director_name,
        ak.actor_count,
        COALESCE(tk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ak ON rm.id = ak.movie_id
    LEFT JOIN 
        TitleKeywords tk ON rm.id = tk.movie_id
    WHERE 
        rm.year_rank <= 5  -- Getting top 5 movies per year
)

SELECT 
    m.title,
    m.production_year,
    m.director_name,
    m.actor_count,
    m.keywords,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        WHEN m.production_year > 2010 THEN 'Recent' 
        ELSE 'Unknown Era' 
    END AS era_category
FROM 
    MoviesWithKeywords m
WHERE 
    (m.actor_count IS NULL OR m.actor_count > 5)
ORDER BY 
    m.production_year DESC, 
    m.title ASC;

WITH NULLHandling AS (
    SELECT 
        title, 
        CASE 
            WHEN keywords IS NULL THEN 'N/A'
            ELSE keywords 
        END AS keywords
    FROM 
        MoviesWithKeywords
)

SELECT 
    title,
    production_year,
    COALESCE(NULLIF(keywords, 'N/A'), 'No Keywords') AS final_keywords
FROM 
    NULLHandling
WHERE 
    final_keywords <> 'No Keywords'
ORDER BY 
    production_year DESC;
