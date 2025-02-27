
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_within_year <= 10
),

ExpandedInfo AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopTitles tt
    LEFT JOIN 
        cast_info ci ON tt.title_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tt.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tt.title_id, tt.title, tt.production_year
)

SELECT 
    ei.title_id,
    ei.title,
    ei.production_year,
    ei.actor_names,
    ei.keywords,
    LENGTH(ei.actor_names) AS actor_names_length,
    LENGTH(ei.keywords) AS keywords_length
FROM 
    ExpandedInfo ei
ORDER BY 
    ei.production_year DESC, ei.title;
