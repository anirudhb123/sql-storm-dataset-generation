
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mc.note, 'No Company Info') AS company_note,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rnk,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS total_movies
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS actors,
        COUNT(c.person_id) AS num_actors,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS named_roles,
        COUNT(DISTINCT c.role_id) AS unique_roles
    FROM 
        cast_info c
    JOIN 
        char_name cn ON c.person_id = cn.imdb_id
    GROUP BY 
        c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.id) AS keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_note,
    cwr.actors,
    cwr.num_actors,
    cwr.named_roles,
    cwr.unique_roles,
    mwk.keyword,
    CASE 
        WHEN rm.total_movies > 1 THEN 'Multiple Movies in Year' 
        ELSE 'Single Movie in Year' 
    END AS movie_count_category,
    CASE 
        WHEN cwr.num_actors > 10 THEN 'Large Cast'
        WHEN cwr.num_actors IS NULL OR cwr.num_actors = 0 THEN 'No Cast Information'
        ELSE 'Regular Cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles cwr ON rm.movie_id = cwr.movie_id
LEFT JOIN 
    MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
WHERE 
    rm.rn <= 3
ORDER BY 
    rm.production_year DESC, 
    mwk.keyword_rank ASC;
