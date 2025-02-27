WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        a.kind_id,
        a.imdb_index
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
PersonRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(ct.kind) AS primary_role
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
),
TopDirectors AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS directed_count
    FROM 
        cast_info ci
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        ci.person_id
    ORDER BY 
        directed_count DESC
    LIMIT 10
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        p.movie_count,
        p.primary_role,
        t.directed_count,
        COALESCE(mw.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonRoleCounts p ON rm.movie_id = p.person_id
    LEFT JOIN 
        TopDirectors t ON rm.movie_id = t.person_id
    LEFT JOIN 
        MoviesWithKeywords mw ON rm.movie_id = mw.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.movie_count,
    fr.primary_role,
    fr.directed_count,
    fr.keywords
FROM 
    FinalResults fr
WHERE 
    fr.production_year BETWEEN 2000 AND 2023
    AND (fr.movie_count IS NULL OR fr.movie_count > 5)
ORDER BY 
    fr.production_year DESC, fr.title_rank
LIMIT 50;
