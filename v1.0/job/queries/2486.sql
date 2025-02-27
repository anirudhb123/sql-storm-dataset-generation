WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        STRING_AGG(mwk.keyword, ', ') AS keywords
    FROM 
        MoviesWithKeywords mwk
    GROUP BY 
        mwk.movie_id, mwk.title
),
RankedMovies AS (
    SELECT 
        mf.movie_id,
        mf.title,
        mf.keywords,
        ROW_NUMBER() OVER (PARTITION BY mf.keywords IS NOT NULL ORDER BY mf.title) AS rank
    FROM 
        FilteredMovies mf
)
SELECT 
    r.movie_id,
    r.title,
    r.keywords,
    COALESCE(mr.role_count, 0) AS role_count,
    CASE 
        WHEN r.rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS rank_category
FROM 
    RankedMovies r
LEFT JOIN 
    MovieRoles mr ON r.movie_id = mr.movie_id
WHERE 
    r.keywords IS NOT NULL
ORDER BY 
    role_count DESC, r.title;
