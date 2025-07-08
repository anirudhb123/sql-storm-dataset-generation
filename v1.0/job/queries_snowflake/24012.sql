
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        title tit ON t.movie_id = tit.id
    WHERE 
        tit.kind_id IN (1, 2)
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(cc.subject_id) AS cast_count
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
),
FinalOutput AS (
    SELECT 
        rt.title,
        rt.production_year,
        ar.person_id,
        ar.role,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        cc.cast_count,
        ar.role_rank
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorRoles ar ON rt.title_id = ar.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rt.title_id = mk.movie_id
    LEFT JOIN 
        CompleteCast cc ON rt.title_id = cc.movie_id
)
SELECT
    title,
    production_year,
    person_id,
    role,
    keywords,
    cast_count
FROM 
    FinalOutput
WHERE 
    (production_year < 1990 OR production_year IS NULL) 
    AND (role_rank <= 2 OR role IS NULL)
ORDER BY 
    production_year DESC, title ASC
LIMIT 100;
