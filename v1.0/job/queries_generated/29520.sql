WITH TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(cc.person_id) AS num_cast_members
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),

KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

AkaNameCounts AS (
    SELECT
        ak.person_id,
        COUNT(ak.id) AS name_count
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
)

SELECT 
    td.title_id,
    td.title,
    td.kind,
    td.production_year,
    td.num_cast_members,
    kd.keywords,
    an.name_count
FROM 
    TitleDetails td
LEFT JOIN 
    KeywordDetails kd ON td.title_id = kd.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = td.title_id
LEFT JOIN 
    AkaNameCounts an ON ci.person_id = an.person_id
WHERE
    td.production_year >= 2000 -- focusing on recent productions
    AND td.kind = 'movie' -- considering only movies
ORDER BY 
    td.production_year DESC, 
    td.title;
