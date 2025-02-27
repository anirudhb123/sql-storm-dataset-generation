WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        YEAR(m.production_year) AS year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY m.id) as cast_count,
        RANK() OVER (ORDER BY m.production_year DESC) as movie_rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    JOIN 
        movie_info mi ON mi.movie_id = t.movie_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.movie_id
    JOIN 
        cast_info c ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
NotableMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.year,
        r.cast_count,
        r.movie_rank,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        RecursiveMovieCTE r
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = r.movie_id
    WHERE 
        r.cast_count > 5 AND r.year >= 2000
)
SELECT 
    nm.title,
    nm.year,
    nm.cast_count,
    nm.keywords,
    CASE 
        WHEN nm.cast_count BETWEEN 6 AND 10 THEN 'Moderate cast'
        WHEN nm.cast_count > 10 THEN 'Rich cast'
        ELSE 'Less cast'
    END AS cast_description,
    NULLIF(nm.keywords, 'No keywords') AS actual_keywords
FROM 
    NotableMovies nm
WHERE 
    nm.movie_rank <= 10 OR nm.keywords LIKE '%action%'
ORDER BY 
    nm.year DESC, nm.cast_count DESC;

-- Additionally, to utilize the outer join concept, consider adding a scenario to track movies with missing details:
LEFT JOIN (
    SELECT 
        m.id AS missing_movie_id,
        COALESCE(m.title, 'Unknown') AS title_missing
    FROM 
        aka_title m
    WHERE 
        m.title IS NULL
) AS missing ON missing.missing_movie_id = nm.movie_id
