WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC NULLS LAST) AS rn,
        COUNT(*) OVER (PARTITION BY t.kind_id) AS total_per_kind
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorMovieCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),

MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id
),

FilteredMovies AS (
    SELECT 
        m.title,
        m.production_year,
        CASE 
            WHEN m.production_year >= 2000 THEN 'Modern'
            WHEN m.production_year < 2000 AND m.production_year >= 1980 THEN 'Classic'
            ELSE 'Vintage'
        END AS era,
        t.total_per_kind,
        COALESCE(k.keywords, 'No Keywords') AS keywords
    FROM 
        RankedTitles m
    JOIN 
        (SELECT kind_id, COUNT(*) AS total_per_kind FROM aka_title GROUP BY kind_id) t ON m.kind_id = t.kind_id 
    LEFT JOIN 
        MoviesWithKeywords k ON m.title_id = k.movie_id
    WHERE 
        m.rn <= 2
)

SELECT 
    fm.title,
    fm.production_year,
    fm.era,
    amc.movie_count,
    fm.keywords
FROM 
    FilteredMovies fm
JOIN 
    ActorMovieCounts amc ON fm.production_year = amc.movie_count
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;