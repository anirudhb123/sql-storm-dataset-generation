WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
        AND mi.info IS NOT NULL
),
TopActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
PopularKeywords AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 5
)
SELECT 
    tt.title,
    tt.production_year,
    ta.name AS top_actor,
    pk.keyword AS popular_keyword
FROM 
    RankedTitles tt
JOIN 
    TopActors ta ON tt.title_id IN (SELECT movie_id FROM cast_info ci WHERE ci.person_id = ta.person_id)
JOIN 
    PopularKeywords pk ON tt.title_id IN (SELECT movie_id FROM movie_keyword mk WHERE mk.keyword_id IN (SELECT id FROM keyword WHERE keyword = pk.keyword))
WHERE 
    tt.title_rank = 1
ORDER BY 
    tt.production_year DESC;
