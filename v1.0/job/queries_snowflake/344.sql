
WITH RankedMovies AS (
    SELECT 
        a.title,
        ch.name AS actor_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.title) AS rn
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        title t ON a.id = t.id
    JOIN 
        char_name ch ON an.name = ch.name
    WHERE 
        t.production_year IS NOT NULL
        AND ci.role_id IS NOT NULL
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
MovieInfoDetailed AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(info_agg.info, 'N/A') AS info_detail,
        COALESCE(kw.keywords, 'No Keywords') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        MovieKeywords kw ON m.id = kw.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id,
            LISTAGG(info, ', ') WITHIN GROUP (ORDER BY info) AS info
        FROM 
            movie_info
        GROUP BY 
            movie_id) info_agg ON m.id = info_agg.movie_id
)
SELECT 
    rm.rn,
    rm.title,
    rm.actor_name,
    rm.production_year,
    mid.info_detail,
    mid.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfoDetailed mid ON rm.title = mid.title
WHERE 
    mid.info_detail IS NOT NULL 
    OR mid.keywords IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.rn;
