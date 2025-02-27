WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS yearly_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredStars AS (
    SELECT 
        a.person_id,
        a.name,
        ci.role_id,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name, ci.role_id
    HAVING 
        COUNT(DISTINCT m.id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword,
        m.production_year
    FROM 
        movie_keyword mk
    INNER JOIN 
        aka_title m ON mk.movie_id = m.id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
        AND m.production_year BETWEEN 2000 AND 2020
),
NullCheck AS (
    SELECT 
        t.movie_id,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        MoviesWithKeywords t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    GROUP BY 
        t.movie_id
    HAVING 
        COUNT(mk.keyword) IS NULL OR COUNT(mk.keyword) < 2
),
FinalResult AS (
    SELECT 
        ms.movie_id,
        ms.title,
        COALESCE(NULLCheck.keyword_count, 0) AS total_keywords,
        rc.yearly_rank
    FROM 
        RankedMovies rc
    FULL OUTER JOIN 
        aka_title ms ON rc.movie_id = ms.id
    LEFT JOIN 
        NullCheck ON ms.id = NullCheck.movie_id
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.total_keywords,
    fr.yearly_rank,
    COALESCE(fs.movie_count, 0) AS starring_count
FROM 
    FinalResult fr
LEFT JOIN 
    FilteredStars fs ON fs.movie_id = fr.movie_id
WHERE 
    fr.yearly_rank = 1
    AND (fr.total_keywords > 1 OR fr.total_keywords IS NULL)
ORDER BY 
    fr.production_year DESC, fr.title;
