WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        aka_name AS ak ON mc.company_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.actor_name
    FROM 
        RankedTitles AS rt
    WHERE 
        rt.rank_per_year <= 5
),
KeywordMovieCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    GROUP BY 
        mk.movie_id
),
FinalOutput AS (
    SELECT 
        fa.title,
        fa.production_year,
        fa.actor_name,
        kmc.keyword_count
    FROM 
        FilteredActors AS fa
    LEFT JOIN 
        KeywordMovieCounts AS kmc ON fa.title_id = kmc.movie_id
)
SELECT 
    f.title,
    f.production_year,
    f.actor_name,
    COALESCE(f.keyword_count, 0) AS keyword_count
FROM 
    FinalOutput AS f
ORDER BY 
    f.production_year DESC, f.actor_name;
