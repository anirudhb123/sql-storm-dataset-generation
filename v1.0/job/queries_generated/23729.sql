WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
        AND m.title IS NOT NULL
),
CharacterCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        COUNT(DISTINCT ti.id) AS title_count
    FROM 
        cast_info ca
    JOIN 
        aka_title ti ON ca.movie_id = ti.id
    GROUP BY 
        c.movie_id
),
MovieCompanyRelations AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        MIN(ct.kind) AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.name IS NOT NULL 
    GROUP BY 
        mc.movie_id
),
FullMovieStats AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        cc.actor_count,
        mcr.company_names,
        mcr.total_companies,
        COALESCE(mcr.company_type, 'Unknown') AS company_type,
        CASE 
            WHEN cc.actor_count > 5 THEN 'Large Cast' 
            ELSE 'Small Cast' 
        END AS cast_size
    FROM 
        RankedMovies m
    LEFT JOIN 
        CharacterCounts cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        MovieCompanyRelations mcr ON m.movie_id = mcr.movie_id
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.company_names,
    f.total_companies,
    f.company_type,
    f.cast_size,
    (CASE 
        WHEN f.production_year >= 2000 THEN 'Modern' 
        ELSE 'Classic' 
     END) AS era,
    STRING_AGG(k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
FROM 
    FullMovieStats f
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    f.movie_id, f.title, f.production_year, f.actor_count, f.total_companies, f.company_names, f.company_type, f.cast_size
HAVING 
    COUNT(k.id) > 0 
    OR f.total_companies IS NULL
ORDER BY 
    f.production_year DESC, f.title;
