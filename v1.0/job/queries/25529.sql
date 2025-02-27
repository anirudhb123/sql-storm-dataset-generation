
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY CHAR_LENGTH(at.title) DESC) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorsCount AS (
    SELECT 
        ct.id AS kind_id,
        COUNT(ci.id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ct.id
),
MovieWithKeyword AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title at ON mk.movie_id = at.movie_id
    GROUP BY 
        at.id
),
CombinedData AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.kind_id,
        ac.actor_count,
        mwk.keywords,
        rt.title_rank
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorsCount ac ON rt.kind_id = ac.kind_id
    LEFT JOIN 
        MovieWithKeyword mwk ON rt.title_id = mwk.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.actor_count,
    cd.keywords
FROM 
    CombinedData cd
WHERE 
    cd.title_rank <= 5  
ORDER BY 
    cd.production_year DESC, 
    CHAR_LENGTH(cd.title) DESC;
