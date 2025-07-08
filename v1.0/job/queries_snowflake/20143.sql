
WITH MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
        COALESCE(c.note, 'No Note') AS note
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

ComplexMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Info') AS info,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT cm.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies cm ON m.id = cm.movie_id
    LEFT JOIN 
        MovieKeywords mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title, mi.info, mk.keywords
),

RankedMovies AS (
    SELECT 
        movie_id,
        title,
        keywords,
        ROW_NUMBER() OVER (ORDER BY company_count DESC) AS ranking,
        DENSE_RANK() OVER (PARTITION BY keywords ORDER BY title) AS keyword_rank
    FROM 
        ComplexMovieInfo
    WHERE 
        title IS NOT NULL
)

SELECT 
    rm.title,
    rm.keywords,
    rm.ranking,
    mc.actor_name,
    mc.actor_order,
    COALESCE(info_type.info, 'No Additional Info') AS additional_info,
    CASE 
        WHEN mc.actor_order < 3 THEN 'Top Actor' 
        ELSE 'Supporting Actor' 
    END AS actor_type
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info info_type ON rm.movie_id = info_type.movie_id
WHERE 
    rm.ranking <= 10 
    AND rm.keywords LIKE '%drama%'
ORDER BY 
    rm.ranking, mc.actor_order
LIMIT 50;
