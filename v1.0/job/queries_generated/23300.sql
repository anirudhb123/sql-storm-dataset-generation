WITH TitleDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        kt.kind AS movie_kind,
        COALESCE(AVG(CAST(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE NULL END AS FLOAT)), 0) AS avg_cast_quality
    FROM 
        aka_title t
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year > 2000 
    GROUP BY 
        t.title, t.production_year, kt.kind
), ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_worked_on,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
), KeywordStats AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS movies_with_keyword
    FROM 
        keyword k
    LEFT JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(mk.movie_id) > 50
), NullHandling AS (
    SELECT 
        m.title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN m.production_year IS NULL THEN 'Unknown Year' ELSE m.production_year::text END) AS production_year_display
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.title
)
SELECT 
    td.title,
    td.production_year,
    td.movie_kind,
    ad.actor_name,
    ad.movies_worked_on,
    ks.keyword,
    ks.movies_with_keyword,
    nh.keyword_count,
    nh.production_year_display,
    CASE 
        WHEN td.avg_cast_quality > 0.75 THEN 'High Quality'
        WHEN td.avg_cast_quality = 0 THEN 'No Cast Info'
        ELSE 'Average Quality' 
    END AS cast_quality_feedback
FROM 
    TitleDetails td
JOIN 
    ActorDetails ad ON td.avg_cast_quality > 0.5
LEFT JOIN 
    KeywordStats ks ON ks.movies_with_keyword > 100
FULL OUTER JOIN 
    NullHandling nh ON nh.keyword_count > 0
WHERE 
    EXISTS (
        SELECT 
            1
        FROM 
            movie_info mi
        WHERE 
            mi.movie_id = td.id AND 
            mi.info ILIKE '%award%'
    )
ORDER BY 
    td.production_year DESC, 
    ad.movies_worked_on DESC,
    td.title;
