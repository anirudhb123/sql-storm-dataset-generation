WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_by_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
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
NullCheck AS (
    SELECT 
        m.movie_id,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN mk.keywords IS NULL THEN 'NULL'
            ELSE 'NOT NULL'
        END AS keyword_status,
        m.rank_by_year,
        m.cast_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
),
AggregateInfo AS (
    SELECT 
        p.person_id,
        ci.role_id,
        COUNT(ci.movie_id) AS total_movies,
        ARRAY_AGG(DISTINCT t.title) AS titles,
        COUNT(DISTINCT ci.movie_id) FILTER (WHERE ci.note IS NOT NULL) AS movies_with_notes
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    GROUP BY 
        p.person_id, ci.role_id
    HAVING 
        COUNT(ci.movie_id) > 5
)
SELECT 
    n.name AS person_name,
    r.title AS movie_title,
    r.production_year,
    n.gender,
    a.keyword_status,
    a.keywords,
    a.rank_by_year,
    a.cast_count,
    ai.total_movies,
    ai.titles,
    ai.movies_with_notes
FROM 
    NullCheck a
JOIN 
    RankedMovies r ON a.movie_id = r.movie_id
JOIN 
    AggregateInfo ai ON ai.role_id = r.movie_id 
JOIN 
    name n ON ai.person_id = n.id
WHERE 
    n.gender = 'F' 
    AND a.rank_by_year <= 5 
    AND (a.cast_count > 0 OR a.keywords <> 'No Keywords')
ORDER BY 
    a.rank_by_year ASC, 
    ai.total_movies DESC;
