WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        at.title,
        ak.name AS actor_name,
        cc.kind AS cast_kind,
        COALESCE(MAX(pi.info), 'No Info') AS person_info
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    JOIN 
        comp_cast_type cc ON ci.person_role_id = cc.id
    GROUP BY 
        at.title, ak.name, cc.kind
),
MovieKeywords AS (
    SELECT 
        at.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
)
SELECT 
    mc.title,
    mc.actor_name,
    mc.cast_kind,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(rm.production_year, 0) AS production_year,
    CASE 
        WHEN rm.title_rank <= 5 THEN 'Top Movie'
        ELSE 'Regular Movie'
    END AS movie_category
FROM 
    MovieCast mc
JOIN 
    MovieKeywords mk ON mc.title = mk.title
LEFT JOIN 
    RankedMovies rm ON mc.title = rm.title
WHERE 
    mc.cast_kind IS NOT NULL
ORDER BY 
    rm.production_year DESC, mc.title;
