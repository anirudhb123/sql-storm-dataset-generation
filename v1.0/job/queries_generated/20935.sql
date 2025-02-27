WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        CAST(COALESCE(NULLIF(a.name_pcode_nf, ''), 'N/A') AS VARCHAR(15)) AS cleaned_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name, a.name_pcode_nf
),

LastMovieInfo AS (
    SELECT 
        ci.person_id,
        MAX(t.production_year) AS last_movie_year,
        MAX(t.title) AS last_movie_title
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        ci.person_id
)

SELECT 
    ad.person_id,
    ad.name,
    ad.cleaned_name,
    ad.movie_count,
    lm.last_movie_year,
    lm.last_movie_title,
    COUNT(DISTINCT kt.keyword) AS keyword_count,
    CASE 
        WHEN lm.last_movie_year IS NULL THEN 'No Movies'
        WHEN lm.last_movie_year > 2020 THEN 'Recent'
        ELSE 'Classic'
    END AS movie_age_category
FROM 
    ActorDetails ad
LEFT JOIN 
    LastMovieInfo lm ON ad.person_id = lm.person_id
LEFT JOIN 
    movie_keyword mk ON ad.movie_count > 0 AND mk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ad.person_id)
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    ad.movie_count > 0
GROUP BY 
    ad.person_id, ad.name, ad.cleaned_name, lm.last_movie_year, lm.last_movie_title
HAVING 
    COUNT(DISTINCT kt.keyword) > 0
ORDER BY 
    ad.movie_count DESC, lm.last_movie_year DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
