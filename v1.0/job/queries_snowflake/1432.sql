
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS distinct_cast_count,
        LISTAGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rw.distinct_cast_count,
    rw.roles,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords,
    CASE 
        WHEN rm.rank_by_title <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS rank_group
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles rw ON rm.movie_id = rw.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.total_movies > 10
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_title;
