WITH RankedTitles AS (
    SELECT 
        at.title, 
        at.production_year, 
        at.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rnk
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword = 'Drama'
),
TopDramaTitles AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        ct.kind 
    FROM 
        RankedTitles rt
    JOIN 
        kind_type ct ON rt.kind_id = ct.id
    WHERE 
        rt.rnk <= 10
),
MovieDetails AS (
    SELECT 
        tt.title, 
        tt.production_year, 
        cc.status_id, 
        ps.info AS person_info
    FROM 
        TopDramaTitles tt
    JOIN 
        complete_cast cc ON cc.movie_id = tt.title
    JOIN 
        person_info ps ON cc.subject_id = ps.person_id
)
SELECT 
    md.title, 
    md.production_year, 
    COUNT(DISTINCT cc.person_id) AS cast_count,
    STRING_AGG(DISTINCT pi.info, ', ') AS person_details
FROM 
    MovieDetails md
JOIN 
    cast_info cc ON cc.movie_id = md.title
JOIN 
    aka_name an ON an.person_id = cc.person_id
WHERE 
    an.name LIKE '%Smith%'
GROUP BY 
    md.title, 
    md.production_year
ORDER BY 
    md.production_year DESC, 
    cast_count DESC;
