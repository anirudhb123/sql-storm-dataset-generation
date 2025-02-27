WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY at.production_year DESC) AS title_rank
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
person_info_agg AS (
    SELECT 
        pi.person_id,
        STRING_AGG(DISTINCT pi.info, ', ') AS aggregated_info
    FROM 
        person_info pi
    GROUP BY 
        pi.person_id
),
highest_rated_titles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(mk.keyword) > 2
)
SELECT 
    p.first_name,
    p.last_name,
    rt.title,
    rt.production_year,
    pia.aggregated_info,
    ht.keyword_count
FROM 
    aka_name p
LEFT JOIN 
    ranked_titles rt ON p.id = rt.aka_id AND rt.title_rank = 1
LEFT JOIN 
    person_info_agg pia ON p.person_id = pia.person_id
LEFT JOIN 
    highest_rated_titles ht ON rt.title = ht.title
WHERE 
    p.name IS NOT NULL
    AND (p.md5sum IS NULL OR p.md5sum <> 'example_md5sum')
ORDER BY 
    ht.keyword_count DESC, rt.production_year ASC
LIMIT 100;
